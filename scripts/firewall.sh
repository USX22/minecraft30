#!/usr/bin/env bash
# Reglas anti-flood para el puerto de Minecraft (ejecutar como root).
# Docker publica puertos por la cadena FORWARD (se salta UFW/INPUT), por eso
# las reglas van en DOCKER-USER, la cadena que Docker reserva para el usuario.
#
# - Máximo 40 conexiones simultáneas por IP (una clase detrás del mismo NAT
#   de la universidad comparte IP, por eso no es más bajo).
# - Máximo ~60 conexiones nuevas por minuto por IP (frena bots/ataques de login).
#
# Lo aplica systemd/minecraft-firewall.service en cada arranque.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root" >&2; exit 1; }

PORT=25565
CHAIN=MC-PROTECT

iptables -N "$CHAIN" 2>/dev/null || iptables -F "$CHAIN"
iptables -N DOCKER-USER 2>/dev/null || true

iptables -A "$CHAIN" -p tcp --syn --dport "$PORT" \
  -m connlimit --connlimit-above 40 --connlimit-mask 32 -j DROP
iptables -A "$CHAIN" -p tcp --syn --dport "$PORT" \
  -m hashlimit --hashlimit-name mc_new --hashlimit-mode srcip \
  --hashlimit-above 60/min --hashlimit-burst 80 -j DROP
iptables -A "$CHAIN" -j RETURN

# Engancha la cadena al inicio de DOCKER-USER (sin duplicar)
iptables -C DOCKER-USER -p tcp --dport "$PORT" -j "$CHAIN" 2>/dev/null \
  || iptables -I DOCKER-USER 1 -p tcp --dport "$PORT" -j "$CHAIN"

echo "Reglas anti-flood aplicadas al puerto $PORT."
