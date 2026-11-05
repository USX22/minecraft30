#!/usr/bin/env bash
# Modo "no premium" (OPCIONAL): permite clientes de Minecraft Java no oficiales.
#   ./scripts/no-premium.sh activar      # pide confirmación; hace backup antes
#   ./scripts/no-premium.sh desactivar   # vuelve a solo cuentas oficiales
#   ./scripts/no-premium.sh estado
# Riesgos y guía completa: docs/10-clientes-no-oficiales.md
source "$(dirname "$0")/lib.sh"

NP=docker-compose.nopremium.yml

compose_files() { grep -E '^COMPOSE_FILE=' .env | cut -d= -f2- || true; }
set_compose_files() {
  sed -i '/^COMPOSE_FILE=/d' .env
  if [[ -n "$1" ]]; then echo "COMPOSE_FILE=$1" >> .env; fi
}
activo() { compose_files | grep -q "$NP"; }
# Nombres de Java en la whitelist (los de Bedrock empiezan por "." y no cambian)
java_whitelist() {
  grep -o '"name": *"[^"]*"' data/whitelist.json 2>/dev/null | cut -d'"' -f4 | grep -v '^\.' || true
}
owner() { grep -E '^SERVER_OWNER=' .env | cut -d= -f2-; }

readd_whitelist() {  # vuelve a añadir los nombres para que tengan el UUID del modo actual
  local n
  for n in "$@"; do
    valid_player "$n"
    rcon "whitelist add $n" >/dev/null || true
  done
  log "Whitelist rehecha: $*"
}

activar() {
  activo && die "El modo no premium ya está activo."
  is_vanilla && die "No es compatible con el modo vanilla (AuthMe es un plugin)."
  cat <<'AVISO'

  MODO NO PREMIUM
  - El servidor dejará de comprobar las cuentas con Microsoft.
  - Cada jugador tendrá que registrarse con contraseña: /register <clave> <clave>
    y al entrar: /login <clave>. El DUEÑO debe entrar y registrarse el primero.
  - Jugar con un Minecraft no comprado va contra los términos de Mojang.
  Guía: docs/10-clientes-no-oficiales.md

AVISO
  if [[ "${NO_CONFIRM:-0}" != 1 ]]; then
    read -r -p "¿Activar el modo no premium? (si/no) " ans
    [[ "$ans" == "si" ]] || die "Cancelado."
  fi

  log "Backup previo..."
  compose exec -T backup backup now >/dev/null 2>&1 || warn "No se pudo hacer el backup previo; se continúa."
  mapfile -t nombres < <(java_whitelist)

  local actual
  actual="$(compose_files)"
  if [[ -z "$actual" ]]; then
    actual="docker-compose.yml"
    [[ -f docker-compose.override.yml ]] && actual+=":docker-compose.override.yml"
  fi
  set_compose_files "$actual:$NP"

  log "Reiniciando en modo no premium (descarga AuthMe)..."
  start_all || die "El servidor no arrancó. Revisa: docker compose logs mc"
  # Segundo arranque: aplica config/patches/authme.json (AuthMe genera su config en el primero)
  compose restart mc
  wait_healthy 900 || die "El servidor no volvió a arrancar. Revisa: docker compose logs mc"

  readd_whitelist "$(owner)" "${nombres[@]}"
  rcon "op $(owner)" >/dev/null || true
  ./scripts/roles.sh setup || true

  log "Modo NO PREMIUM activo."
  log "1) El dueño ($(owner)) entra YA y escribe: /register <clave> <clave>"
  log "2) Si no ves [Dueño] en el chat tras entrar: ./scripts/roles.sh setup"
  log "3) Cada jugador nuevo: ./scripts/whitelist.sh agregar <nick> y que se registre al entrar."
}

desactivar() {
  activo || die "El modo no premium no está activo."
  mapfile -t nombres < <(java_whitelist)
  local nuevo
  nuevo="$(compose_files | sed "s#:$NP##; s#$NP:##")"
  case "$nuevo" in
    docker-compose.yml|docker-compose.yml:docker-compose.override.yml) nuevo="" ;;
  esac
  set_compose_files "$nuevo"

  log "Volviendo a solo cuentas oficiales (se quita AuthMe)..."
  start_all || die "El servidor no arrancó. Revisa: docker compose logs mc"
  readd_whitelist "${nombres[@]}"
  ./scripts/roles.sh setup || true
  log "Modo normal restaurado: solo cuentas oficiales de Minecraft."
  log "Los jugadores que solo tenían cliente no oficial ya no podrán entrar."
}

case "${1:-}" in
  activar) activar ;;
  desactivar) desactivar ;;
  estado) if activo; then echo "Modo NO PREMIUM: activo"; else echo "Modo normal (solo cuentas oficiales)"; fi ;;
  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
