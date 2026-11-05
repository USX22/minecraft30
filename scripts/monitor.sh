#!/usr/bin/env bash
# Mide el servidor cada 30 s: jugadores, TPS, MSPT, CPU y RAM.
# Guarda los datos en monitor-<fecha>.csv (útil para gráficas del informe).
#   ./scripts/monitor.sh          # hasta que pulses Ctrl+C
#   ./scripts/monitor.sh 20       # 20 mediciones (10 minutos) y termina
# TPS: 20 = perfecto, <18 = lag.  MSPT: ms por tick; por encima de 50 hay lag.
source "$(dirname "$0")/lib.sh"

out="monitor-$(date +%Y%m%d-%H%M).csv"
limpio() { sed -e 's/§.//g' -e 's/\x1b\[[0-9;]*m//g'; }
echo "hora,jugadores,tps_1min,mspt_promedio,cpu,ram" | tee "$out"
n=0
while [[ -z "${1:-}" || $n -lt $1 ]]; do
  jugadores="$(rcon list | limpio | grep -oE '[0-9]+' | head -1)"
  tps="$(rcon tps | limpio | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  mspt="$(rcon mspt | limpio | grep -oE '[0-9]+\.[0-9]+' | sed -n 2p)"
  recursos="$(docker stats --no-stream --format '{{.CPUPerc}},{{.MemUsage}}' mc | cut -d/ -f1)"
  echo "$(date +%T),${jugadores:-?},${tps:-?},${mspt:-?},${recursos}" | tee -a "$out"
  n=$((n + 1))
  [[ -n "${1:-}" && $n -ge $1 ]] || sleep 30
done
log "Datos guardados en $out"
