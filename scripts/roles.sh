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

  rcon 'lp group moderador meta setprefix 50 "&9[Mod] "'   >/dev/null
  rcon 'lp group admin meta setprefix 90 "&c[Admin] "'     >/dev/null
  rcon 'lp group owner meta setprefix 100 "&6[Dueño] "'    >/dev/null

  log "Permisos de jugador (default)..."
  set_perms default \
    essentials.spawn essentials.home essentials.sethome essentials.delhome \
    essentials.tpa essentials.tpaccept essentials.tpdeny essentials.back \
    essentials.msg essentials.reply essentials.mail essentials.mail.send \
    essentials.afk essentials.list essentials.motd essentials.rules \
    essentials.helpop essentials.ignore essentials.seen \
    coreprotect.inspect.own

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
    spark.tps spark.healthreport \
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
    rcon "lp user ${owner} parent set owner" >/dev/null && log "Dueño '${owner}' asignado al grupo owner."
  fi
}

set_role() {  # set_role <grupo> <jugador>
  valid_player "$2"
  rcon "lp user $2 parent set $1"
  log "$2 ahora es: $1"
}

case "${1:-}" in
  setup)  setup ;;
  admin)  set_role admin "${2:-}" ;;
  mod)    set_role moderador "${2:-}" ;;
  quitar) set_role default "${2:-}" ;;
  info)   valid_player "${2:-}"; rcon "lp user $2 info" ;;
  lista)  rcon "lp listgroups" ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
