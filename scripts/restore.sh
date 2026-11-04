#!/usr/bin/env bash
# Restaura el mundo desde un backup.
#   ./scripts/restore.sh                  # lista los backups disponibles
#   ./scripts/restore.sh backups/<archivo>.tar.zst
# La carpeta data actual NO se borra: se mueve a data.antes-de-restaurar-<fecha>.
# Si la extracción falla, se vuelve a poner automáticamente el mundo anterior.
source "$(dirname "$0")/lib.sh"

file="${1:-}"
if [[ -z "$file" ]]; then
  echo "Backups disponibles (el más reciente primero):"; ls -1t backups/*.tar* 2>/dev/null || echo "(ninguno)"
  exit 0
fi
[[ -f "$file" ]] || die "No existe $file"
name="$(basename "$file")"
[[ "$(cd "$(dirname "$file")" && pwd)" == "$ROOT_DIR/backups" ]] || die "El archivo debe estar dentro de backups/"

read -r -p "Esto DETIENE el servidor y reemplaza el mundo por $name. ¿Continuar? (si/no) " ans
[[ "$ans" == "si" ]] || die "Cancelado."

log "Deteniendo servidor..."
compose down

old="data.antes-de-restaurar-$(date +%Y%m%d-%H%M%S)"
log "Moviendo data/ actual a $old"
sudo mv data "$old"
sudo install -d -o 1000 -g 1000 -m 0755 data

# Si algo falla a partir de aquí, se recupera el mundo anterior
rollback() {
  warn "La restauración falló: se recupera el mundo anterior."
  sudo rm -rf data
  sudo mv "$old" data
  start_all || true
}
trap rollback ERR

log "Extrayendo $name ..."
# Se usa la imagen de backup (trae tar y zstd) y el usuario del servidor (1000),
# así no hace falta instalar nada en la VM y los archivos quedan con el dueño correcto.
docker run --rm --user 1000:1000 --network none \
  -v "$ROOT_DIR/backups:/backups:ro" -v "$ROOT_DIR/data:/data" \
  --entrypoint tar itzg/mc-backup:latest -xf "/backups/$name" -C /data
[[ -d data/world ]] || { warn "El backup no contiene world/"; false; }

log "Arrancando..."
start_all
trap - ERR
log "Restauración completa. El mundo anterior quedó en $old (bórralo cuando estés seguro)."
