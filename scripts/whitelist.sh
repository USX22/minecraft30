#!/usr/bin/env bash
# Gestión de la whitelist (lista de jugadores permitidos).
#
# Jugadores de Java Edition (por nick):
#   ./scripts/whitelist.sh agregar <nick> [<nick>...]
#   ./scripts/whitelist.sh quitar  <nick>
#
# Jugadores de Bedrock (por gamertag de Xbox, entre comillas si tiene espacios).
# Si es un jugador nuevo, el comando abre la whitelist hasta 3 minutos para
# que entre una vez, lo agrega y la vuelve a cerrar automáticamente.
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

# Agrega un jugador de Bedrock. Primero lo intenta con Floodgate; si Floodgate
# aún no conoce la cuenta (jugador nuevo), abre la whitelist hasta 3 minutos,
# espera a que el jugador entre, lo agrega con su nombre exacto y la cierra.
agregar_bedrock() {
  local g="$1" since nombre
  if CONSOLE_WAIT=5 console_out "fwhitelist add $g" | grep -qiE "added|already"; then
    log "Jugador de Bedrock '$g' añadido a la whitelist."
    return
  fi
  warn "Floodgate aún no conoce la cuenta '$g' (pasa con jugadores nuevos)."
  since="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rcon "whitelist off" >/dev/null
  trap 'rcon "whitelist on" >/dev/null; log "Whitelist cerrada de nuevo."' EXIT
  log "Whitelist ABIERTA 3 minutos: que '$g' entre AHORA desde Bedrock (IP, puerto 19132)."
  for _ in $(seq 1 36); do
    # Floodgate antepone "." y cambia espacios por "_" (y recorta a 16 caracteres)
    nombre="$(docker logs --since "$since" mc 2>&1 \
      | grep -oE "Floodgate player logged in as \.[A-Za-z0-9_]+ joined" \
      | awk '{print $6}' | grep -iF ".${g:0:15}" | head -1)"
    if [[ -n "$nombre" ]]; then
      rcon "whitelist add $nombre"
      log "Listo: $nombre ya está en la whitelist (desde ahora entra directo)."
      return
    fi
    sleep 5
  done
  warn "'$g' no entró en 3 minutos. Revisa el gamertag y vuelve a intentarlo."
  return 1
}

case "${1:-}" in
  agregar) shift; [[ $# -gt 0 ]] || die "Falta el jugador"
           if grep -qE '^COMPOSE_FILE=.*nopremium' .env 2>/dev/null; then
             # Modo no premium: UUID calculado del nombre (ver scripts/no-premium.sh)
             ./scripts/no-premium.sh agregar "$@"
           else
             for p in "$@"; do valid_player "$p"; rcon "whitelist add $p"; done
           fi ;;
  quitar)  valid_player "${2:-}"; rcon "whitelist remove $2" ;;
  bedrock) agregar_bedrock "$(gamertag "${2:-}")" ;;
  quitar-bedrock) g="$(gamertag "${2:-}")"; CONSOLE_WAIT=3 console_out "fwhitelist remove $g" | grep -vE "STUN|skin api" ;;
  lista)   rcon "whitelist list" ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
