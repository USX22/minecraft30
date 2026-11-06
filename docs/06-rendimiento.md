# 6. Rendimiento y prueba de carga

## Indicador clave: TPS

Minecraft simula el mundo en *ticks*. El objetivo son **20 TPS** (un tick cada 50 ms). Si un tick tarda más, el TPS baja y los jugadores notan lag (bloques que reaparecen, mobs a saltos).

| TPS | Experiencia |
|---|---|
| 19.5–20 | Perfecta |
| 17–19.5 | Aceptable |
| < 15 | Lag notable |

```bash
./scripts/console.sh tps
```

```bash
./scripts/console.sh "spark healthreport"
```

## Dimensionamiento para 30 jugadores

**Capacidad:** Medido en prueba con 2 núcleos: **90 jugadores (bots) con TPS 20**. Estimación prudente para jugadores reales: **~50–70** con 2 OCPU/12 GB y **~100** con 4 OCPU/24 GB; con el servidor oficial vanilla, ~20–30 y ~30–40. Datos en [RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md) y explicación en el [MANUAL §3](MANUAL.md#3-cuántos-jugadores-soporta).

| Recurso | Necesidad estimada (Paper, 30 jugadores, distancia 8) | Asignado (VM 2 OCPU / 12 GB) |
|---|---|---|
| RAM del servidor (heap) | 5–8 GB | 8 GB (`MC_MEMORY`) |
| RAM del sistema + overhead JVM | ~2–3 GB | 4 GB restantes + 4 GB swap |
| CPU | El hilo principal es el cuello de botella; 2+ núcleos para generación de chunks, red y GC | 2 OCPU Ampere (= 2 núcleos físicos) |
| Disco | Mundo 2–10 GB + backups | 100 GB |
| Red | ~50–150 kbit/s por jugador → ~5 Mbit/s para 30 | Oracle: hasta 1 Gbit/s por OCPU; 10 TB/mes de salida gratis |

Con 4 OCPU / 24 GB hay margen de sobra: sube `MC_MEMORY=12G`, `CONTAINER_MEM_LIMIT=14g` y `VIEW_DISTANCE=10`.

### Optimizaciones aplicadas

| Optimización | Dónde | Efecto |
|---|---|---|
| Paper en vez de vanilla | `TYPE: PAPER` | Carga de chunks asíncrona, entidades y redstone optimizados |
| Flags de Aikar | `USE_AIKAR_FLAGS` | GC G1 afinado: pausas cortas |
| Heap fijo | `-Xms = -Xmx` (automático) | Sin pausas por redimensionar memoria |
| `view-distance 8` / `simulation-distance 6` | `.env` | Menos chunks cargados por jugador (el mayor consumo) |
| Pregeneración con Chunky + borde de mundo | [docs/02 §6](02-despliegue-oracle-cloud.md#6-pregenerar-el-mundo-muy-recomendado) | La generación de terreno (muy costosa) no ocurre mientras se juega |
| Límites de entidades por chunk, colisiones | `config/patches/` | Granjas y acumulaciones no hunden el TPS |
| Swap con `swappiness=10` | `bootstrap-host.sh` | Colchón ante picos sin perjudicar el rendimiento normal |

> **Cálculo de chunks:** con `view-distance 8` cada jugador mantiene (2·8+1)² = 289 chunks cargados. 30 jugadores dispersos = ~8 700 chunks. Con distancia 12 serían 625 por jugador (más del doble). Por eso la distancia es el ajuste más importante.

## Prueba de carga con bots

`tests/load/` conecta N bots ([mineflayer](https://github.com/PrismarineJS/mineflayer)) que caminan, saltan y corren al azar, y registra el TPS cada 30 s.

Se usa un **servidor de prueba** (modo offline, sin whitelist, escuchando solo en `localhost`) definido en `tests/load/docker-compose.test.yml`, con su propio mundo en `tests/load/data`. **Nunca** pongas el servidor real en modo offline.

Requisitos: Node.js 18+ en la VM (`sudo apt install -y nodejs npm`). Detén el servidor real antes, porque usan el mismo puerto y nombre de contenedor:

```bash
docker compose down
```

```bash
./tests/load/run-load-test.sh 35
```

Resultado en `tests/load/resultados.csv` (hora, jugadores, TPS). Úsalo para una gráfica en el informe. Al terminar:

```bash
docker compose -f docker-compose.yml -f tests/load/docker-compose.test.yml down
```

```bash
docker compose up -d
```

Con el servidor de prueba arrancado también puedes ejecutar la **prueba automática de roles y moderación** (12 comprobaciones: permisos, mute, kick, tempban, rollback de CoreProtect, inmunidad de admins, whitelist):

```bash
cd tests/load && node roles-test.js
```

Resultados reales de este proyecto: [RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md).

> Los bots generan **más** carga que jugadores reales en cuanto a movimiento aleatorio, pero no construyen granjas ni redstone. Es una buena estimación, no una garantía.

## Prueba de carga contra el servidor real (bots desde tu computadora)

La forma más realista: el servidor de verdad (en Azure/Oracle) y los bots en **otra** computadora, para que no le quiten CPU. Duración: ~30 minutos. Hazlo **sin jugadores conectados** y con la pregeneración pausada (`./scripts/console.sh "chunky pause"`).

**1. En la VM**, activa el modo prueba (los bots no tienen cuenta oficial; la whitelist sigue activa y solo deja entrar a `bot_1`…`bot_40`):

```bash
./scripts/prueba-carga.sh activar 40
```

**2. En tu PC con Windows** (PowerShell). Instala Node.js (una vez) y cierra/abre PowerShell:

```powershell
winget install OpenJS.NodeJS.LTS
```

Descarga los bots:

```powershell
mkdir $HOME\bots-mc; cd $HOME\bots-mc; iwr https://raw.githubusercontent.com/usx22/minecraft30/claude/eager-newton-q1uimf/tests/load/bots.js -OutFile bots.js; iwr https://raw.githubusercontent.com/usx22/minecraft30/claude/eager-newton-q1uimf/tests/load/package.json -OutFile package.json; npm install
```

**3. Lanza los bots en dos ventanas de PowerShell** (un solo proceso con muchos bots se satura). Ventana 1:

```powershell
cd $HOME\bots-mc; $env:HOST="IP_PUBLICA"; $env:BOTS="18"; $env:BOT_START="1"; $env:DELAY_MS="2500"; node bots.js
```

Ventana 2 (igual pero `BOT_START="19"`):

```powershell
cd $HOME\bots-mc; $env:HOST="IP_PUBLICA"; $env:BOTS="18"; $env:BOT_START="19"; $env:DELAY_MS="2500"; node bots.js
```

**4. En la VM, mide** durante 10 minutos (guarda `monitor-<fecha>.csv` para el informe):

```bash
./scripts/monitor.sh 20
```

✅ Con `MAX_PLAYERS=36`, entran 36 bots y los demás reciben "Server is full" (eso también prueba el límite). Buen resultado: **TPS ≥ 19** y **MSPT < 40**.

**5. Termina:** `Ctrl+C` en las ventanas de los bots, y en la VM:

```bash
./scripts/prueba-carga.sh desactivar
```

Reanuda la pregeneración si estaba en curso: `./scripts/console.sh "chunky continue"`.

## Medir el ping real

- **Java:** en *Multijugador*, pon el ratón sobre las **barritas de señal** del servidor: muestra los milisegundos. < 100 ms es bueno; < 150 ms es jugable.
- **Bedrock:** el indicador de la lista suele marcar "mala conexión" con servidores Geyser aunque se juegue bien; fíate de cómo responde dentro del juego.
- Pide a 2–3 compañeros que lo miren desde sus casas: el ping depende de cada conexión.

## Si hay lag

1. `./scripts/console.sh "spark profiler start"`, espera 2–3 minutos, `./scripts/console.sh "spark profiler stop"` → abre el enlace: muestra qué plugin, entidad o chunk consume el tiempo.
2. Baja `VIEW_DISTANCE` a 7 o `SIMULATION_DISTANCE` a 5 en `.env` y `docker compose up -d`.
3. Busca acumulaciones de entidades: `./scripts/console.sh "minecraft:kill @e[type=item]"`.
4. Comprueba si la VM usa mucho swap (`free -h`): si es así, baja `MC_MEMORY` 1 GB.
