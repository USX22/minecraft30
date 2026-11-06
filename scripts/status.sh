#!/usr/bin/env bash
# Estado del servidor: contenedores, salud, jugadores, TPS y recursos.
source "$(dirname "$0")/lib.sh"

echo "=== Contenedores ==="
compose ps
echo
echo "=== Salud: $(docker inspect -f '{{.State.Health.Status}}' mc 2>/dev/null || echo 'detenido') ==="
echo
echo "=== Jugadores ==="
rcon list || true
echo
echo "=== TPS (20 = perfecto) ==="
if is_vanilla; then rcon "tick query" || true; else rcon tps || true; fi
echo
echo "=== Recursos ==="
docker stats --no-stream mc mc-backup || true
echo
echo "=== Disco ==="
df -h "$ROOT_DIR" | tail -1
du -sh data backups 2>/dev/null || true
echo
echo "=== Últimos backups ==="
ls -lht backups 2>/dev/null | head -5 || true
