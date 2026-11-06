#!/usr/bin/env bash
# Levanta el servidor de prueba, conecta bots y registra TPS cada 30 s.
#   ./tests/load/run-load-test.sh 35
set -euo pipefail
cd "$(dirname "$0")/../.."
BOTS="${1:-35}"
CF=(-f docker-compose.yml -f tests/load/docker-compose.test.yml)
[[ -f .env ]] || { echo "Primero crea .env (./scripts/install.sh)"; exit 1; }

mkdir -p tests/load/data && sudo chown 1000:1000 tests/load/data
docker compose "${CF[@]}" up -d mc
echo "Esperando a que el servidor de prueba arranque..."
until [[ "$(docker inspect -f '{{.State.Health.Status}}' mc)" == healthy ]]; do sleep 10; done

(cd tests/load && npm install --silent && BOTS="$BOTS" node bots.js) &
BOTS_PID=$!
trap 'kill $BOTS_PID 2>/dev/null || true' EXIT

echo "fecha,jugadores,tps" > tests/load/resultados.csv
for _ in $(seq 1 20); do
  sleep 30
  players="$(docker compose "${CF[@]}" exec -T mc rcon-cli list | sed 's/§.//g;s/\x1b\[[0-9;]*m//g' | grep -oE '[0-9]+' | head -1)"
  tps="$(docker compose "${CF[@]}" exec -T mc rcon-cli tps | sed 's/§.//g;s/\x1b\[[0-9;]*m//g' | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  echo "$(date +%T),$players,$tps" | tee -a tests/load/resultados.csv
done
echo "Resultados en tests/load/resultados.csv"
