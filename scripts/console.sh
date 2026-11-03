#!/usr/bin/env bash
# Consola del servidor.
#   ./scripts/console.sh                 # consola interactiva (salir: Ctrl+C)
#   ./scripts/console.sh "say Hola"      # ejecutar un comando suelto
source "$(dirname "$0")/lib.sh"
if [[ $# -eq 0 ]]; then
  compose exec mc rcon-cli
else
  rcon "$*"
fi
