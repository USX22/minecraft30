#!/usr/bin/env bash
# Hace un backup inmediato (además de los automáticos cada BACKUP_INTERVAL).
source "$(dirname "$0")/lib.sh"
log "Iniciando backup manual..."
compose exec -T backup backup now
log "Backup terminado:"
ls -lht backups | head -3
