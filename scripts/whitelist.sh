#!/usr/bin/env bash
# Gestión de la whitelist (lista de jugadores permitidos).
#
# Jugadores de Java Edition (por nick):
#   ./scripts/whitelist.sh agregar <nick> [<nick>...]
#   ./scripts/whitelist.sh quitar  <nick>
#
# Jugadores de Bedrock (por gamertag de Xbox; los espacios se escriben igual,
# entre comillas). El jugador debe haber intentado entrar UNA vez antes.
#   ./scripts/whitelist.sh bedrock        "<gamertag>"
#   ./scripts/whitelist.sh quitar-bedrock "<gamertag>"
#
#   ./scripts/whitelist.sh lista
source "$(dirname "$0")/lib.sh"

# Floodgate cambia los espacios del gamertag por "_"
gamertag() {
  local g="${1:-}"
  [[ "$g" =~ ^[A-Za-z0-9\ ]{1,16}$ ]] || die "Gamertag inválido: '$g' (letras, números y espacios, máx. 16)"
  printf '%s' "${g// /_}"
}

case "${1:-}" in
  agregar) shift; [[ $# -gt 0 ]] || die "Falta el jugador"
           for p in "$@"; do valid_player "$p"; rcon "whitelist add $p"; done ;;
  quitar)  valid_player "${2:-}"; rcon "whitelist remove $2" ;;
  bedrock) g="$(gamertag "${2:-}")"
           CONSOLE_WAIT=5 console_out "fwhitelist add $g" | grep -vE "STUN|skin api"
           echo "Si dice que no encuentra al usuario: que intente entrar una vez desde Bedrock y repite este comando." ;;
  quitar-bedrock) g="$(gamertag "${2:-}")"; CONSOLE_WAIT=3 console_out "fwhitelist remove $g" | grep -vE "STUN|skin api" ;;
  lista)   rcon "whitelist list" ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
