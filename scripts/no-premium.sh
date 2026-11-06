#!/usr/bin/env bash
# Modo "no premium" (OPCIONAL): permite clientes de Minecraft Java no oficiales.
#   ./scripts/no-premium.sh activar      # pide confirmación; hace backup antes
#   ./scripts/no-premium.sh desactivar   # vuelve a solo cuentas oficiales
#   ./scripts/no-premium.sh estado
#   ./scripts/no-premium.sh arreglar-whitelist   # rehace la whitelist para el modo actual
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

# Escribe en data/whitelist.json el UUID correcto de cada nombre para el modo
# indicado y recarga la whitelist. No se usa "whitelist add" porque el servidor
# recuerda el UUID antiguo del nombre (usercache) y lo reutilizaría.
#   offline -> UUID calculado del nombre (modo no premium)
#   online  -> UUID oficial consultado a Mojang
readd_whitelist() {  # readd_whitelist <offline|online> <nombre>...
  local modo="$1"; shift
  local n
  for n in "$@"; do valid_player "$n"; done
  [[ $# -gt 0 ]] || return 0
  sudo python3 -I - "$modo" "$ROOT_DIR/data/whitelist.json" "$@" <<'PY'
import hashlib, json, sys, urllib.request, uuid
modo, ruta, nombres = sys.argv[1], sys.argv[2], sys.argv[3:]
def offline(n):
    h = bytearray(hashlib.md5(("OfflinePlayer:" + n).encode()).digest())
    h[6] = h[6] & 0x0F | 0x30; h[8] = h[8] & 0x3F | 0x80
    return str(uuid.UUID(bytes=bytes(h)))
def oficial(n):
    with urllib.request.urlopen("https://api.mojang.com/users/profiles/minecraft/" + n, timeout=10) as r:
        return str(uuid.UUID(json.load(r)["id"]))
try:
    lista = json.load(open(ruta))
except Exception:
    lista = []
for n in nombres:
    try:
        u = offline(n) if modo == "offline" else oficial(n)
    except Exception as e:
        print(f"  (aviso) no se pudo obtener el UUID oficial de {n}: {e}"); continue
    lista = [e for e in lista if e["name"].lower() != n.lower()]
    lista.append({"uuid": u, "name": n})
    print(f"  {n} -> {u}")
json.dump(lista, open(ruta, "w"), indent=2)
PY
  rcon "whitelist reload" >/dev/null
  log "Whitelist rehecha para el modo $modo."
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

  readd_whitelist offline "$(owner)" "${nombres[@]}"
  ./scripts/roles.sh setup >/dev/null 2>&1 || true

  log "Modo NO PREMIUM activo."
  log "1) El dueño ($(owner)) entra YA y escribe: /register <clave> <clave>"
  log "2) Después de registrarte, en la VM: ./scripts/roles.sh setup  (asigna [Dueño] a tu cuenta no premium)"
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
  readd_whitelist online "${nombres[@]}"
  ./scripts/roles.sh setup || true
  log "Modo normal restaurado: solo cuentas oficiales de Minecraft."
  log "Los jugadores que solo tenían cliente no oficial ya no podrán entrar."
}

case "${1:-}" in
  activar) activar ;;
  desactivar) desactivar ;;
  estado) if activo; then echo "Modo NO PREMIUM: activo"; else echo "Modo normal (solo cuentas oficiales)"; fi ;;
  agregar)  # usado por whitelist.sh en modo no premium
    shift; activo || die "El modo no premium no está activo."; readd_whitelist offline "$@" ;;
  arreglar-whitelist)  # rehace la whitelist (nombres de Java) para el modo actual
    mapfile -t nombres < <(java_whitelist)
    if activo; then readd_whitelist offline "$(owner)" "${nombres[@]}"; else readd_whitelist online "${nombres[@]}"; fi ;;
  *) sed -n '2,6p' "$0"; exit 1 ;;
esac
