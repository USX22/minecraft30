#!/usr/bin/env bash
# Gestión de la whitelist (lista de jugadores permitidos).
#   ./scripts/whitelist.sh agregar <jugador> [<jugador>...]
#   ./scripts/whitelist.sh quitar  <jugador>
#   ./scripts/whitelist.sh lista
source "$(dirname "$0")/lib.sh"

case "${1:-}" in
  agregar) shift; [[ $# -gt 0 ]] || die "Falta el jugador"
           for p in "$@"; do valid_player "$p"; rcon "whitelist add $p"; done ;;
  quitar)  valid_player "${2:-}"; rcon "whitelist remove $2" ;;
  lista)   rcon "whitelist list" ;;
  *) sed -n '2,5p' "$0"; exit 1 ;;
esac
