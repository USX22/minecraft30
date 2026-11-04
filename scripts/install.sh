#!/usr/bin/env bash
# Primera instalación del servidor (ejecutar desde la carpeta del proyecto).
#   ./scripts/install.sh
source "$(dirname "$0")/lib.sh"

command -v docker >/dev/null || die "Docker no está instalado. Ejecuta antes: sudo ./scripts/bootstrap-host.sh"

if [[ ! -f .env ]]; then
  cp .env.example .env
  pass="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)"
  sed -i "s|^RCON_PASSWORD=.*|RCON_PASSWORD=${pass}|" .env
  chmod 640 .env
  getent group mcadmin >/dev/null && chgrp mcadmin .env
  log ".env creado con contraseña RCON aleatoria."
  warn "Edita .env (SERVER_OWNER, WHITELIST, MC_MEMORY...) y vuelve a ejecutar este script."
  exit 0
fi

grep -q 'CAMBIAR_ESTA_CONTRASENA' .env && die "Cambia RCON_PASSWORD en .env"
grep -q '^SERVER_OWNER=TuNickDeMinecraft' .env && die "Pon tu nick real en SERVER_OWNER (.env)"
# .env tiene la contraseña RCON: solo el dueño y el grupo mcadmin pueden leerlo
chmod 640 .env
getent group mcadmin >/dev/null && chgrp mcadmin .env

# El servidor corre como UID 1000 (no root): las carpetas deben ser suyas
mkdir -p data backups
if [[ "$(stat -c %u data)" != "1000" ]]; then
  log "Ajustando dueño de data/ y backups/ a UID 1000 (requiere sudo)..."
  sudo chown -R 1000:1000 data backups
fi
# Los backups contienen el mundo completo: solo el servidor (UID 1000) y el
# grupo mcadmin pueden entrar en la carpeta (los archivos se crean con modo 666).
sudo chmod 2750 backups
if getent group mcadmin >/dev/null; then sudo chgrp mcadmin backups; fi

if [[ "${SKIP_NICK_CHECK:-0}" != "1" ]]; then
  log "Verificando nicks de SERVER_OWNER y WHITELIST contra Mojang..."
  owner="$(grep -E '^SERVER_OWNER=' .env | cut -d= -f2-)"
  wl="$(grep -E '^WHITELIST=' .env | cut -d= -f2- | tr ',' ' ')"
  # shellcheck disable=SC2086
  check_nicks "$owner" $wl || die "Corrige los nicks en .env y vuelve a ejecutar."
fi

log "Descargando imágenes..."
compose pull
log "Arrancando (la primera vez tarda varios minutos: descarga Paper y plugins)..."
start_all || die "El servidor no arrancó. Revisa: docker compose logs mc"

# Reinicio para que se apliquen los parches de config/patches (anti-xray)
log "Primer arranque OK. Reiniciando una vez para aplicar parches de configuración..."
compose restart mc
wait_healthy 600 || die "El servidor no volvió a arrancar. Revisa: docker compose logs mc"

log "Creando roles (LuckPerms)..."
./scripts/roles.sh setup

log "¡Servidor listo! Conéctate a <IP-pública>:25565"
