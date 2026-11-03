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

# Valida nombres de jugador de Minecraft (3-16 caracteres, letras/números/_)
valid_player() {
  [[ "${1:-}" =~ ^[A-Za-z0-9_]{3,16}$ ]] || die "Nombre de jugador inválido: '${1:-}'"
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

# ¿Está activo el modo vanilla (servidor oficial, sin plugins)?
is_vanilla() {
  compose config 2>/dev/null | grep -qE '^\s+TYPE: "?VANILLA"?\s*$'
}
