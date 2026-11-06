#!/usr/bin/env bash
# Actualización segura del servidor:
#   1. Avisa a los jugadores en el chat
#   2. Hace un backup
#   3. Descarga la última configuración (git pull) y las imágenes nuevas
#   4. Reinicia: al arrancar se actualizan Paper (último build) y los plugins
#   5. Verifica que el servidor quede "healthy"
#
#   ./scripts/update.sh            # con avisos de 5 min
#   ./scripts/update.sh --ahora    # sin esperar (servidor vacío / mantenimiento)
#
# Se ejecuta automáticamente cada semana con systemd/minecraft-update.timer
source "$(dirname "$0")/lib.sh"

announce() { rcon "say §e[Mantenimiento] $*" >/dev/null 2>&1 || true; }

if [[ "${1:-}" != "--ahora" ]]; then
  log "Avisando a los jugadores..."
  announce "El servidor se reiniciará para actualizarse en 5 minutos."
  sleep 240
  announce "Reinicio en 1 minuto. ¡Busca un lugar seguro!"
  sleep 50
  announce "Reiniciando en 10 segundos..."
  sleep 10
fi

log "Backup previo a la actualización..."
compose exec -T backup backup now || warn "El backup falló; se continúa porque hay backups automáticos."

if [[ -d .git ]]; then
  log "Actualizando configuración desde git..."
  git pull --ff-only || warn "git pull falló (¿cambios locales?). Se usa la configuración actual."
fi

before_mc="$(docker image inspect -f '{{.Id}}' itzg/minecraft-server:latest 2>/dev/null || true)"
log "Descargando imágenes nuevas..."
compose pull
after_mc="$(docker image inspect -f '{{.Id}}' itzg/minecraft-server:latest 2>/dev/null || true)"
[[ "$before_mc" != "$after_mc" ]] && log "Hay una imagen nueva del servidor."

log "Reiniciando servicios..."
if start_all --force-recreate --remove-orphans; then
  log "Actualización completada. Servidor en línea."
  docker image prune -f >/dev/null
else
  die "El servidor no quedó healthy tras actualizar. Revisa 'docker compose logs mc'. Para volver atrás: ./scripts/restore.sh"
fi
