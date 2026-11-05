#!/usr/bin/env bash
# Plugins adicionales desde Modrinth (https://modrinth.com/plugins).
#   ./scripts/plugins.sh buscar <texto>      # busca plugins compatibles con el servidor
#   ./scripts/plugins.sh agregar <slug>      # ej. worldedit (comprueba compatibilidad y reinicia)
#   ./scripts/plugins.sh quitar  <slug>
#   ./scripts/plugins.sh lista               # base + adicionales
# El "slug" es el nombre en la URL de Modrinth: modrinth.com/plugin/<slug>
# Solo se aceptan plugins con versión ESTABLE para Paper y para la versión de
# Minecraft actual del servidor: así un plugin nunca impide arrancar ni obliga
# a bajar de versión el mundo.
source "$(dirname "$0")/lib.sh"

API=https://api.modrinth.com/v2
extras() { grep -E '^EXTRA_PLUGINS=' .env | cut -d= -f2- | tr ',' '\n' | sed '/^$/d' || true; }
guardar() {  # guardar <lista separada por espacios/saltos>
  local v
  v="$(printf '%s\n' "$@" | sed '/^$/d' | sort -u | paste -sd, -)"
  if grep -qE '^EXTRA_PLUGINS=' .env; then
    sed -i "s|^EXTRA_PLUGINS=.*|EXTRA_PLUGINS=${v}|" .env
  else
    echo "EXTRA_PLUGINS=${v}" >> .env
  fi
}
version_mc() {
  grep -oE 'MC: [0-9.]+' data/version_history.json 2>/dev/null | cut -d' ' -f2 \
    || die "No se pudo leer la versión del servidor (¿está arrancado?)."
}
valid_slug() { [[ "${1:-}" =~ ^[a-z0-9_-]{2,64}$ ]] || die "Slug inválido: '${1:-}' (míralo en la URL de Modrinth)"; }
reiniciar() {
  log "Reiniciando el servidor para aplicar (2–3 min)..."
  compose up -d mc
  wait_healthy 900 || die "El servidor no arrancó. Revisa: docker compose logs mc  (y quita el plugin)"
  log "Listo. Comprueba con: ./scripts/console.sh plugins"
}

compatible() {  # compatible <slug> <version> -> imprime la versión estable o falla
  curl -sf "$API/project/$1/version?loaders=%5B%22paper%22%5D&game_versions=%5B%22$2%22%5D" \
    | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
rel = [v for v in d if v["version_type"] == "release"]
if not rel: sys.exit(1)
print(rel[0]["version_number"])' 2>/dev/null
}

case "${1:-}" in
  buscar)
    [[ -n "${2:-}" ]] || die "Escribe qué buscar, ej: ./scripts/plugins.sh buscar mapa"
    v="$(version_mc)"
    q="$(python3 -I -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$2")"
    curl -sf "$API/search?query=$q&limit=10&facets=%5B%5B%22categories:paper%22%5D,%5B%22versions:$v%22%5D%5D" \
      | python3 -I -c '
import json, sys
for h in json.load(sys.stdin)["hits"]:
    print("%-28s %10d descargas  %s" % (h["slug"], h["downloads"], h["description"].replace("\n", " ")[:70]))' \
      || die "No se pudo consultar Modrinth."
    echo "(compatibles con Paper $v; para instalar: ./scripts/plugins.sh agregar <slug>)" ;;
  agregar)
    valid_slug "${2:-}"; slug="$2"; v="$(version_mc)"
    if extras | grep -qx "$slug"; then die "'$slug' ya está en la lista."; fi
    if ver="$(compatible "$slug" "$v")"; then
      log "'$slug' $ver es compatible con Paper $v."
    else
      die "'$slug' no existe o no tiene versión ESTABLE para Paper $v. No se instala (podría impedir arrancar el servidor)."
    fi
    mapfile -t lista < <(extras)
    guardar "${lista[@]}" "$slug"
    reiniciar ;;
  quitar)
    valid_slug "${2:-}"; slug="$2"
    extras | grep -qx "$slug" || die "'$slug' no está en la lista de plugins adicionales."
    mapfile -t lista < <(extras | grep -vx "$slug")
    guardar "${lista[@]}"
    log "Se quitará '$slug' (sus archivos de configuración en data/plugins/ se conservan)."
    reiniciar ;;
  lista)
    echo "Plugins base (docker-compose.yml): luckperms essentialsx coreprotect chunky lpc-chat viaversion viabackwards + Geyser y Floodgate"
    echo "Plugins adicionales (.env EXTRA_PLUGINS): $(extras | paste -sd' ' -)"
    echo "Cargados ahora:"; rcon plugins | sed -e 's/§.//g' -e 's/\x1b\[[0-9;]*m//g' ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
