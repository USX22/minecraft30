#!/usr/bin/env bash
# Funciones compartidas por los scripts. Se usa con: source "$(dirname "$0")/lib.sh"
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log()  { printf '\033[1;32m[%s]\033[0m %s\n' "$(date '+%F %T')" "$*"; }
warn() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

compose() { docker compose "$@"; }

# Ejecuta un comando de consola del servidor vía RCON (red interna de Docker)
rcon() { compose exec -T mc rcon-cli "$@"; }

# Ejecuta un comando en la consola y muestra la respuesta del log.
# Para comandos que responden de forma asíncrona (LuckPerms), cuya respuesta
# RCON no recibe.
console_out() {
  local since
  since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  compose exec -T mc mc-send-to-console "$*"
  sleep "${CONSOLE_WAIT:-2}"
  docker logs --since "$since" mc 2>&1 \
    | sed -e 's/\x1b\[[0-9;]*m//g' -e 's/^\[[0-9:]*\] \[[^]]*\]: //' \
    | grep -vE 'RCON (Listener|Client)'
}

# Valida nombres de jugador: Java (3-16 caracteres, letras/números/_) o
# Bedrock vía Floodgate (empiezan por "." y los espacios son "_")
valid_player() {
  [[ "${1:-}" =~ ^(\.[A-Za-z0-9_]{1,16}|[A-Za-z0-9_]{3,16})$ ]] \
    || die "Nombre de jugador inválido: '${1:-}'"
}

# Espera a que el contenedor 'mc' esté "healthy" (máx. $1 segundos)
wait_healthy() {
  local timeout="${1:-600}" waited=0 status
  while (( waited < timeout )); do
    status="$(docker inspect -f '{{.State.Health.Status}}' mc 2>/dev/null || echo missing)"
    [[ "$status" == "healthy" ]] && return 0
    sleep 10; waited=$((waited + 10))
  done
  return 1
}

# Arranca el servidor primero, espera a que esté listo y luego el resto
# (el backup depende de que el servidor esté "healthy"; en el primer arranque
# o tras actualizar, descargar Paper/plugins puede tardar varios minutos).
start_all() {
  compose up -d "$@" mc
  wait_healthy 900 || return 1
  compose up -d "$@"
}

# Comprueba que cada nick exista como cuenta oficial de Minecraft.
# Un nick inexistente en WHITELIST/SERVER_OWNER hace que el servidor no arranque.
check_nicks() {
  local nick code bad=0
  for nick in "$@"; do
    [[ -z "$nick" ]] && continue
    valid_player "$nick"
    code="$(curl -s -o /dev/null -w '%{http_code}' "https://api.mojang.com/users/profiles/minecraft/${nick}" || echo 000)"
    case "$code" in
      200) ;;
      000) warn "No se pudo verificar '$nick' (sin conexión con Mojang); se continúa." ;;
      *)   warn "El nick '$nick' no existe como cuenta oficial de Minecraft (revisa mayúsculas y tipeo)."; bad=1 ;;
    esac
  done
  return "$bad"
}

# ¿Está activo el modo vanilla (servidor oficial, sin plugins)?
is_vanilla() {
  compose config 2>/dev/null | grep -qE '^\s+TYPE: "?VANILLA"?\s*$'
}
