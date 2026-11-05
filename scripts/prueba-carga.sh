#!/usr/bin/env bash
# Prueba de carga con bots lanzados desde OTRA computadora (ver docs/06).
#   ./scripts/prueba-carga.sh activar [N]   # modo prueba + whitelist bot_1..bot_N (por defecto 40)
#   ./scripts/prueba-carga.sh desactivar    # vuelve al modo normal y quita los bots de la whitelist
# Mientras dura la prueba, mide con:  ./scripts/monitor.sh
source "$(dirname "$0")/lib.sh"

files=(-f docker-compose.yml -f docker-compose.prueba.yml)
[[ -f docker-compose.override.yml ]] && files+=(-f docker-compose.override.yml)
N="${2:-40}"
if ! [[ "$N" =~ ^[0-9]+$ ]] || (( N < 1 || N > 200 )); then die "Número de bots inválido: $N"; fi

case "${1:-}" in
  activar)
    warn "Se reinicia el servidor en MODO PRUEBA (cuentas sin verificar, solo bots en whitelist)."
    compose "${files[@]}" up -d mc
    wait_healthy 900 || die "El servidor no arrancó. Revisa: docker compose logs mc"
    log "Añadiendo bot_1..bot_$N a la whitelist..."
    for i in $(seq 1 "$N"); do rcon "whitelist add bot_$i" >/dev/null; done
    log "Modo prueba ACTIVO. Lanza los bots desde tu computadora (docs/06-rendimiento.md)"
    log "y mide aquí con: ./scripts/monitor.sh"
    log "Al terminar: ./scripts/prueba-carga.sh desactivar"
    ;;
  desactivar)
    log "Volviendo al modo normal (solo cuentas oficiales)..."
    compose up -d mc
    wait_healthy 900 || die "El servidor no arrancó. Revisa: docker compose logs mc"
    log "Quitando bots de la whitelist..."
    for i in $(seq 1 200); do rcon "whitelist remove bot_$i" >/dev/null 2>&1 || true; done
    log "Modo normal restaurado."
    ;;
  *) sed -n '2,5p' "$0"; exit 1 ;;
esac
