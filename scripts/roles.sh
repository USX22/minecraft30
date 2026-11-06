#!/usr/bin/env bash
# Gestión de roles con LuckPerms.
#
#   ./scripts/roles.sh setup              # crea/actualiza los grupos (idempotente)
#   ./scripts/roles.sh admin  <jugador>   # hace admin a un jugador
#   ./scripts/roles.sh mod    <jugador>   # hace moderador a un jugador
#   ./scripts/roles.sh quitar <jugador>   # lo devuelve a jugador normal
#   ./scripts/roles.sh info   <jugador>   # muestra su grupo y permisos
#   ./scripts/roles.sh lista              # lista grupos
#
# Jerarquía (cada rol hereda los permisos del anterior):
#   default (jugador) -> moderador -> admin -> owner
#
# Principio de mínimo privilegio:
#   - Solo el dueño (y la consola) puede cambiar roles: los admins NO tienen
#     permisos de LuckPerms ni pueden darse OP, así no pueden escalar privilegios.
source "$(dirname "$0")/lib.sh"

set_perms() {  # set_perms <grupo> <permiso> [<permiso> ...]   ("-perm" = denegar)
  local group="$1"; shift
  local p
  for p in "$@"; do
    if [[ "$p" == -* ]]; then
      rcon "lp group ${group} permission set ${p#-} false" >/dev/null
    else
      rcon "lp group ${group} permission set ${p} true" >/dev/null
    fi
  done
}

setup() {
  log "Creando grupos..."
  for g in moderador admin owner; do rcon "lp creategroup ${g}" >/dev/null || true; done

  rcon "lp group default setweight 0"   >/dev/null
  rcon "lp group moderador setweight 50" >/dev/null
  rcon "lp group admin setweight 90"     >/dev/null
  rcon "lp group owner setweight 100"    >/dev/null

  rcon "lp group moderador parent add default" >/dev/null
  rcon "lp group admin parent add moderador"   >/dev/null
  rcon "lp group owner parent add admin"       >/dev/null

  # Prefijos en formato MiniMessage (lo exige el plugin de chat LPC).
  # 'clear' antes de fijar evita prefijos duplicados si se repite setup.
  for g in moderador admin owner; do rcon "lp group ${g} meta clear prefix" >/dev/null; done
  rcon 'lp group moderador meta setprefix 50 "<blue>[Mod]</blue> "'   >/dev/null
  rcon 'lp group admin meta setprefix 90 "<red>[Admin]</red> "'       >/dev/null
  rcon 'lp group owner meta setprefix 100 "<gold>[Dueño]</gold> "'    >/dev/null

  log "Permisos de jugador (default)..."
  set_perms default \
    essentials.spawn essentials.home essentials.sethome essentials.delhome \
    essentials.tpa essentials.tpaccept essentials.tpdeny essentials.back \
    essentials.msg essentials.reply essentials.mail essentials.mail.send \
    essentials.afk essentials.list essentials.motd essentials.rules \
    essentials.helpop essentials.ignore essentials.seen

  log "Permisos de moderador..."
  set_perms moderador \
    essentials.kick essentials.kick.notify \
    essentials.mute essentials.mute.notify essentials.mute.offline \
    essentials.tempban essentials.tempban.offline essentials.ban.notify \
    essentials.unban \
    essentials.jail essentials.jails essentials.togglejail essentials.jail.notify \
    essentials.tp essentials.tphere essentials.tpo \
    essentials.vanish essentials.invsee essentials.socialspy \
    essentials.whois essentials.helpop.receive essentials.broadcast \
    essentials.gamemode essentials.gamemode.spectator essentials.gamemode.survival \
    coreprotect.inspect coreprotect.lookup coreprotect.rollback coreprotect.restore \
    spark.tps spark.healthreport bukkit.command.tps \
    minecraft.command.whitelist

  log "Permisos de admin..."
  # Todo, excepto gestionar roles/OP (evita escalada de privilegios)
  set_perms admin '*' \
    -luckperms.* \
    -minecraft.command.op -minecraft.command.deop \
    -essentials.sudo.exempt

  log "Permisos de owner..."
  set_perms owner '*' luckperms.*

  log "Roles listos: default < moderador < admin < owner"
  owner="$(grep -E '^SERVER_OWNER=' .env | cut -d= -f2- || true)"
  if [[ -n "$owner" ]]; then
    rcon "lp user ${owner} parent set owner" >/dev/null
    verify_role "$owner" owner
  fi
}

# Comprueba en LuckPerms que el jugador quedó en el grupo indicado.
# (LuckPerms responde de forma asíncrona, por eso se lee la consola.)
verify_role() {  # verify_role <jugador> <grupo>
  if CONSOLE_WAIT=3 console_out "lp user $1 info" | grep -qi "Primary Group: $2"; then
    log "Verificado: '$1' está en el grupo $2."
  else
    warn "No se pudo confirmar que '$1' esté en el grupo $2."
    warn "Suele pasar si el jugador nunca ha entrado al servidor: que entre una vez y repite:"
    warn "  ./scripts/roles.sh $( [[ $2 == owner ]] && echo setup || echo "${2/moderador/mod} $1" )"
  fi
}

set_role() {  # set_role <grupo> <jugador>
  valid_player "$2"
  rcon "lp user $2 parent set $1" >/dev/null
  verify_role "$2" "$1"
}

# --- Modo vanilla: no hay LuckPerms, solo OP de Minecraft (nivel 3) ---
vanilla_roles() {
  case "${1:-}" in
    setup)  log "Modo vanilla: no hay grupos. Los admins son OP de nivel 3 (ver MANUAL.md §12)." ;;
    admin)  valid_player "${2:-}"; rcon "op $2"; log "$2 ahora es OP (admin vanilla)." ;;
    mod)    die "El servidor vanilla no permite moderadores con permisos limitados. Usa 'admin' (OP) o cambia a Paper." ;;
    quitar) valid_player "${2:-}"; rcon "deop $2" ;;
    info|lista) echo "Operadores (data/ops.json):"; grep -o '"name": *"[^"]*"' data/ops.json 2>/dev/null | cut -d'"' -f4 ;;
    *) sed -n '2,12p' "$0"; exit 1 ;;
  esac
}
if is_vanilla; then vanilla_roles "$@"; exit 0; fi

case "${1:-}" in
  setup)  setup ;;
  admin)  set_role admin "${2:-}" ;;
  mod)    set_role moderador "${2:-}" ;;
  quitar) set_role default "${2:-}" ;;
  info)   valid_player "${2:-}"; console_out "lp user $2 info" ;;
  lista)  console_out "lp listgroups" ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
