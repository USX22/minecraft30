#!/usr/bin/env bash
# Prepara y asegura una VM Ubuntu 22.04/24.04 nueva (Oracle Cloud u otra)
# o una Raspberry Pi 4/5 con Raspberry Pi OS / Debian de 64 bits.
#   sudo ./scripts/bootstrap-host.sh
#   sudo PERFIL=raspberrypi ./scripts/bootstrap-host.sh   # PC de casa que no es Pi
#
# En una Raspberry Pi (se detecta sola, ver docs/08-raspberry-pi.md):
#   - El firewall permite todo lo que venga de la red de la casa, para no
#     cortar Pi-hole, dashboards u otros servicios que ya tengas en la Pi.
#   - No se crea swap extra si ya hay (desgasta la microSD).
#   - Se activa el control de memoria de Linux (cgroup) que Docker necesita
#     para respetar el límite de RAM del servidor.
#
# Qué hace:
#   1. Actualiza el sistema y activa actualizaciones de seguridad automáticas
#   2. Instala Docker + Docker Compose
#   3. SSH solo con llave (sin contraseñas, sin login de root)
#   4. Firewall: solo SSH (22), Minecraft Java (25565) y Bedrock (19132-19133)
#   5. fail2ban: bloquea IPs que intentan adivinar el acceso SSH
#   6. Swap de 4 GB (colchón ante picos de memoria)
#   7. Instala los servicios systemd (arranque, firewall y actualización semanal)
#      y crea el grupo 'mcadmin' para administradores de sistema adicionales
#
# Recomendado clonar el proyecto en /opt/minecraft30 (ver MANUAL.md §8).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo" >&2; exit 1; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUN_USER="${SUDO_USER:-ubuntu}"
log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

is_raspberry_pi() {
  [[ "${PERFIL:-}" == "raspberrypi" ]] && return 0
  [[ "${PERFIL:-}" == "vm" ]] && return 1
  grep -qa 'Raspberry Pi' /proc/device-tree/model 2>/dev/null
}
# shellcheck disable=SC1091
OS_ID="$(. /etc/os-release && echo "$ID")"
case "$OS_ID" in
  ubuntu|debian) ;;
  *) echo "Sistema no soportado ($OS_ID). Usa Ubuntu, Debian o Raspberry Pi OS de 64 bits." >&2; exit 1 ;;
esac
case "$(dpkg --print-architecture)" in
  amd64|arm64) ;;
  *) echo "Se necesita un sistema de 64 bits (amd64 o arm64). En una Raspberry Pi instala la versión 64-bit." >&2; exit 1 ;;
esac

log "1/7 Actualizando sistema..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl git openssl zstd fail2ban python3-systemd unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades
cat > /etc/apt/apt.conf.d/52minecraft-auto-reboot <<'EOF'
// Reinicia de madrugada si una actualización de seguridad lo requiere
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "05:30";
EOF

log "2/7 Instalando Docker..."
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  # shellcheck disable=SC1091
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS_ID} $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker
usermod -aG docker "$RUN_USER"
# Rotación de logs de Docker (evita llenar el disco). Si ya existe una
# configuración propia (otros contenedores en la máquina), no se toca.
if [[ ! -s /etc/docker/daemon.json ]]; then
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "20m", "max-file": "5" },
  "live-restore": true
}
EOF
  systemctl restart docker
else
  echo "  (se conserva /etc/docker/daemon.json existente; revisa que tenga rotación de logs)"
fi

log "3/7 Endureciendo SSH..."
if [[ -s "/home/$RUN_USER/.ssh/authorized_keys" ]]; then
  cat > /etc/ssh/sshd_config.d/99-minecraft-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
EOF
  systemctl reload ssh 2>/dev/null || systemctl reload sshd
else
  echo "  (omitido: $RUN_USER no tiene llave SSH; no se desactivan contraseñas para no dejarte fuera)"
fi

log "4/7 Configurando firewall..."
if [[ -f /etc/iptables/rules.v4 ]] && grep -q InstanceServices /etc/iptables/rules.v4; then
  # Imagen de Oracle Cloud: ya trae iptables (bloquea todo menos SSH) y Oracle
  # recomienda NO usar UFW. Solo abrimos 25565 antes de la regla REJECT.
  # Se edita rules.v4 directamente (en vez de 'netfilter-persistent save') para
  # no guardar también las reglas dinámicas que crea Docker.
  open_oracle_port() {  # open_oracle_port <puerto> [tcp|udp]
    local port="$1" proto="${2:-tcp}"
    local rule="-A INPUT -p $proto -m state --state NEW -m $proto --dport $port -j ACCEPT"
    if ! grep -qF -- "$rule" /etc/iptables/rules.v4; then
      sed -i "0,/^-A INPUT .*REJECT/s||${rule}\n&|" /etc/iptables/rules.v4
    fi
    if ! iptables -C INPUT -p "$proto" -m state --state NEW -m "$proto" --dport "$port" -j ACCEPT 2>/dev/null; then
      local reject_line
      reject_line="$(iptables -L INPUT --line-numbers | awk '/REJECT/ {print $1; exit}')"
      iptables -I INPUT "${reject_line:-1}" -p "$proto" -m state --state NEW -m "$proto" --dport "$port" -j ACCEPT
    fi
  }
  open_oracle_port 25565 tcp   # Java
  open_oracle_port 19132 udp   # Bedrock (RakNet)
  open_oracle_port 19132 tcp   # Bedrock (señalización NetherNet)
  open_oracle_port 19133 udp   # Bedrock (NetherNet)
  echo "  Oracle: recuerda abrir también en la Security List de la VCN: 25565/TCP, 19132/TCP, 19132/UDP y 19133/UDP (ver docs)."
else
  apt-get install -y ufw
  if is_raspberry_pi; then
    # Servidor en casa: la red local (y Tailscale, si lo usas) sigue
    # llegando a todo (Pi-hole, dashboards...). Desde internet solo entra
    # lo que reenvíe el router; los jugadores llegan por el túnel de playit.
    for net in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 fe80::/10 fd00::/8; do
      ufw allow from "$net" comment 'Red local de la casa'
    done
    if ip link show tailscale0 >/dev/null 2>&1; then
      ufw allow in on tailscale0 comment 'Tailscale'
    fi
  fi
  ufw default deny incoming
  ufw default allow outgoing
  ufw limit 22/tcp comment 'SSH con limite de intentos'
  ufw allow 25565/tcp comment 'Minecraft Java'
  ufw allow 19132 comment 'Minecraft Bedrock (TCP+UDP)'
  ufw allow 19133/udp comment 'Minecraft Bedrock NetherNet'
  ufw --force enable
fi

log "5/7 Activando fail2ban para SSH..."
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled  = true
backend  = systemd
maxretry = 5
findtime = 10m
bantime  = 1h
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

log "6/7 Creando swap de 4 GB..."
if [[ -n "$(swapon --noheadings --show=NAME 2>/dev/null)" ]]; then
  # Ya hay swap (p. ej. la de Raspberry Pi OS): no se crea otra, para no
  # gastar disco ni desgastar la microSD.
  echo "  (ya hay swap activa: $(swapon --noheadings --show=NAME,SIZE | tr '\n' ' '))"
elif ! swapon --show | grep -q /swapfile; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
sysctl -w vm.swappiness=10 >/dev/null
echo 'vm.swappiness=10' > /etc/sysctl.d/99-minecraft.conf

# Raspberry Pi: el kernel trae desactivado el control de memoria (cgroup).
# Sin él, Docker ignora el límite de RAM del servidor (CONTAINER_MEM_LIMIT).
REBOOT_NEEDED=0
if is_raspberry_pi && ! grep -qw memory /sys/fs/cgroup/cgroup.controllers 2>/dev/null; then
  CMDLINE=/boot/firmware/cmdline.txt
  [[ -f "$CMDLINE" ]] || CMDLINE=/boot/cmdline.txt
  if [[ -f "$CMDLINE" ]] && ! grep -q 'cgroup_enable=memory' "$CMDLINE"; then
    cp "$CMDLINE" "$CMDLINE.bak"
    sed -i '1 s/$/ cgroup_enable=memory cgroup_memory=1/' "$CMDLINE"
    echo "  Activado el control de memoria en $CMDLINE (copia en $CMDLINE.bak)."
    REBOOT_NEEDED=1
  fi
fi

log "7/7 Instalando servicios systemd..."
for unit in minecraft.service minecraft-firewall.service minecraft-update.service minecraft-update.timer; do
  sed -e "s|@PROJECT_DIR@|${PROJECT_DIR}|g" -e "s|@RUN_USER@|${RUN_USER}|g" \
    "$PROJECT_DIR/systemd/$unit" > "/etc/systemd/system/$unit"
done
chmod +x "$PROJECT_DIR"/scripts/*.sh
# El firewall corre como root: se instala una copia propiedad de root para que
# un usuario sin privilegios no pueda modificar lo que root ejecuta.
install -m 0755 -o root -g root "$PROJECT_DIR/scripts/firewall.sh" /usr/local/sbin/minecraft-firewall.sh
systemctl daemon-reload
systemctl enable minecraft.service minecraft-firewall.service minecraft-update.timer
systemctl start minecraft-firewall.service minecraft-update.timer

mkdir -p "$PROJECT_DIR/data" "$PROJECT_DIR/backups"
chown -R 1000:1000 "$PROJECT_DIR/data" "$PROJECT_DIR/backups"

# Grupo 'mcadmin': todos los administradores de sistema pueden usar el proyecto
# (ver scripts/sysadmins.sh). data/ y backups/ siguen siendo del UID 1000.
groupadd -f mcadmin
usermod -aG mcadmin "$RUN_USER"
find "$PROJECT_DIR" \( -path "$PROJECT_DIR/data" -o -path "$PROJECT_DIR/backups" \
     -o -path "$PROJECT_DIR/tests/load/data" \) -prune -o -exec chgrp mcadmin {} +
find "$PROJECT_DIR" \( -path "$PROJECT_DIR/data" -o -path "$PROJECT_DIR/backups" \
     -o -path "$PROJECT_DIR/tests/load/data" \) -prune -o -type d -exec chmod g+rwxs {} +
chmod -R g+rwX "$PROJECT_DIR/.git" "$PROJECT_DIR/scripts" "$PROJECT_DIR/docs" 2>/dev/null || true
[[ -f "$PROJECT_DIR/.env" ]] && chmod 640 "$PROJECT_DIR/.env"
chgrp mcadmin "$PROJECT_DIR/backups" && chmod 2750 "$PROJECT_DIR/backups"
git config --system --add safe.directory "$PROJECT_DIR"
git -C "$PROJECT_DIR" config core.sharedRepository group

if [[ "$REBOOT_NEEDED" == 1 ]]; then
  log "Listo. REINICIA la Raspberry Pi (sudo reboot) para activar el control de memoria."
  echo "    Después vuelve a entrar y ejecuta:  cd $PROJECT_DIR && ./scripts/install.sh"
else
  log "Listo. Cierra la sesión SSH y vuelve a entrar (para los grupos docker y mcadmin) y ejecuta:"
  echo "    cd $PROJECT_DIR && ./scripts/install.sh"
fi
