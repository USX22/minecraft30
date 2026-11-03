#!/usr/bin/env bash
# Gestión de ADMINISTRADORES DE SISTEMA (personas con acceso SSH a la VM).
# No confundir con los admins del juego (esos se gestionan con roles.sh).
#
#   sudo ./scripts/sysadmins.sh agregar <usuario> "<llave pública SSH>"
#   sudo ./scripts/sysadmins.sh quitar  <usuario>
#   sudo ./scripts/sysadmins.sh lista
#
# Un administrador de sistema:
#   - entra por SSH solo con su llave (nunca con contraseña)
#   - pertenece a los grupos 'docker' y 'mcadmin': puede usar todos los scripts
#   - NO recibe sudo (no puede tocar el sistema operativo). Para dárselo:
#       sudo usermod -aG sudo <usuario>
#
# ATENCIÓN: pertenecer al grupo 'docker' equivale en la práctica a ser root
# (Docker puede montar cualquier carpeta). Solo dalo a personas de confianza.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo" >&2; exit 1; }

user="${2:-}"
valid_user() { [[ "$user" =~ ^[a-z][a-z0-9_-]{1,30}$ ]] || { echo "Usuario inválido: '$user' (minúsculas, números, - y _)" >&2; exit 1; }; }

case "${1:-}" in
  agregar)
    valid_user
    key="${3:-}"
    [[ "$key" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+)\ [A-Za-z0-9+/=]+ ]] \
      || { echo "Falta la llave pública o no es válida (debe empezar por ssh-ed25519 o ssh-rsa)" >&2; exit 1; }
    groupadd -f mcadmin
    id "$user" >/dev/null 2>&1 || adduser --disabled-password --gecos "" "$user"
    usermod -aG docker,mcadmin "$user"
    install -d -m 700 -o "$user" -g "$user" "/home/$user/.ssh"
    touch "/home/$user/.ssh/authorized_keys"
    grep -qxF "$key" "/home/$user/.ssh/authorized_keys" || echo "$key" >> "/home/$user/.ssh/authorized_keys"
    chown "$user:$user" "/home/$user/.ssh/authorized_keys"
    chmod 600 "/home/$user/.ssh/authorized_keys"
    echo "Listo. '$user' ya puede entrar con:  ssh $user@<IP_PUBLICA>  y trabajar en /opt/minecraft30"
    ;;
  quitar)
    valid_user
    [[ "$user" != "${SUDO_USER:-}" ]] || { echo "No puedes quitarte a ti mismo." >&2; exit 1; }
    pkill -u "$user" 2>/dev/null || true
    deluser --remove-home "$user"
    echo "Usuario '$user' eliminado y sus sesiones cerradas."
    ;;
  lista)
    echo "Miembros de mcadmin: $(getent group mcadmin | cut -d: -f4)"
    echo "Miembros de docker:  $(getent group docker | cut -d: -f4)"
    echo "Miembros de sudo:    $(getent group sudo | cut -d: -f4)"
    ;;
  *) sed -n '2,17p' "$0"; exit 1 ;;
esac
