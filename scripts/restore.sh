#!/usr/bin/env bash
# Restaura el mundo desde un backup.
#   ./scripts/restore.sh                  # lista los backups disponibles
#   ./scripts/restore.sh backups/<archivo>.tar.zst
# La carpeta data actual NO se borra: se mueve a data.antes-de-restaurar-<fecha>
source "$(dirname "$0")/lib.sh"

file="${1:-}"
if [[ -z "$file" ]]; then
  echo "Backups disponibles:"; ls -1t backups/*.tar* 2>/dev/null || echo "(ninguno)"
  exit 0
fi
[[ -f "$file" ]] || die "No existe $file"

read -r -p "Esto DETIENE el servidor y reemplaza el mundo por $file. ¿Continuar? (si/no) " ans
[[ "$ans" == "si" ]] || die "Cancelado."

log "Deteniendo servidor..."
compose down

old="data.antes-de-restaurar-$(date +%Y%m%d-%H%M%S)"
log "Moviendo data/ actual a $old"
sudo mv data "$old"
sudo mkdir -p data

log "Extrayendo $file ..."
case "$file" in
  *.tar.zst) sudo tar --zstd -xf "$file" -C data ;;
  *.tgz|*.tar.gz) sudo tar -xzf "$file" -C data ;;
  *) sudo tar -xf "$file" -C data ;;
esac
sudo chown -R 1000:1000 data

log "Arrancando..."
compose up -d
if wait_healthy 900; then
  log "Restauración completa."
else
  die "No arrancó; revisa 'docker compose logs mc'. El mundo anterior está en $old"
fi
