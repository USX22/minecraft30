#!/usr/bin/env bash
# Bot de Discord para administrar el servidor (plugin DiscordSRV).
# Guía para crear el bot y obtener los IDs: docs/11-mods-plugins-y-bots.md §4
#   ./scripts/discord.sh configurar <TOKEN_DEL_BOT> <ID_CANAL_CHAT> <ID_CANAL_CONSOLA>
#   ./scripts/discord.sh estado
#   ./scripts/discord.sh quitar
# Qué hace el bot:
#   - Canal de chat: une el chat del juego y el de Discord (en ambos sentidos).
#   - Canal de CONSOLA: todo lo que se escribe ahí se ejecuta como consola del
#     servidor (whitelist, roles, kick...). Hazlo visible SOLO para admins.
#   - En el canal de chat, quien tenga el rol "Admin Minecraft" puede usar
#     !c <comando>; cualquiera puede escribir "playerlist" para ver quién juega.
source "$(dirname "$0")/lib.sh"

CFG=data/plugins/DiscordSRV/config.yml
ROL="Admin Minecraft"

instalado() { grep -qE '^EXTRA_PLUGINS=.*discordsrv' .env 2>/dev/null; }

case "${1:-}" in
  configurar)
    token="${2:-}"; chat="${3:-}"; consola="${4:-}"
    [[ "$token" =~ ^[A-Za-z0-9._-]{50,120}$ ]] || die "Token inválido (cópialo de Discord Developer Portal → Bot → Reset Token)."
    [[ "$chat" =~ ^[0-9]{17,20}$ ]] || die "ID del canal de chat inválido (clic derecho en el canal → Copiar ID)."
    [[ "$consola" =~ ^[0-9]{17,20}$ ]] || die "ID del canal de consola inválido."
    [[ "$chat" != "$consola" ]] || die "El canal de chat y el de consola deben ser distintos."
    if ! instalado; then
      log "Instalando el plugin DiscordSRV..."
      ./scripts/plugins.sh agregar discordsrv
    fi
    [[ -f "$CFG" ]] || die "No existe $CFG todavía. Espera a que el servidor arranque y repite."
    sudo sed -i \
      -e "s|^BotToken: .*|BotToken: \"$token\"|" \
      -e "s|^Channels: .*|Channels: {\"global\": \"$chat\"}|" \
      -e "s|^DiscordConsoleChannelId: .*|DiscordConsoleChannelId: \"$consola\"|" \
      -e "s|^DiscordChatChannelConsoleCommandRolesAllowed: .*|DiscordChatChannelConsoleCommandRolesAllowed: [\"$ROL\"]|" \
      -e "s|^DiscordChatChannelConsoleCommandWhitelistBypassRoles: .*|DiscordChatChannelConsoleCommandWhitelistBypassRoles: [\"$ROL\"]|" \
      "$CFG"
    sudo chmod 640 "$CFG"   # contiene el token del bot
    log "Configuración guardada. Reiniciando para conectar el bot..."
    compose restart mc
    wait_healthy 900 || die "El servidor no volvió a arrancar. Revisa: docker compose logs mc"
    "$0" estado ;;
  estado)
    instalado || { echo "DiscordSRV no está instalado (./scripts/discord.sh configurar ...)."; exit 0; }
    docker logs --since 10m mc 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -iE "DiscordSRV" \
      | grep -iE "connected|ready|token|invalid|intent|error|channel" | tail -6
    echo "(Si dice 'Disallowed intents': activa SERVER MEMBERS INTENT y MESSAGE CONTENT INTENT en el bot, docs/11 §4)" ;;
  quitar)
    instalado || die "DiscordSRV no está instalado."
    ./scripts/plugins.sh quitar discordsrv ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
