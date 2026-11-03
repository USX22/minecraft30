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

**Capacidad estimada:** ~40–50 jugadores con 2 OCPU/12 GB y ~70–100 con 4 OCPU/24 GB usando Paper; con el servidor oficial vanilla, ~20–30 y ~30–40. Detalle en el [MANUAL §3](MANUAL.md#3-cuántos-jugadores-soporta).

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

> Los bots generan **más** carga que jugadores reales en cuanto a movimiento aleatorio, pero no construyen granjas ni redstone. Es una buena estimación, no una garantía.

## Si hay lag

1. `./scripts/console.sh "spark profiler start"`, espera 2–3 minutos, `./scripts/console.sh "spark profiler stop"` → abre el enlace: muestra qué plugin, entidad o chunk consume el tiempo.
2. Baja `VIEW_DISTANCE` a 7 o `SIMULATION_DISTANCE` a 5 en `.env` y `docker compose up -d`.
3. Busca acumulaciones de entidades: `./scripts/console.sh "minecraft:kill @e[type=item]"`.
4. Comprueba si la VM usa mucho swap (`free -h`): si es así, baja `MC_MEMORY` 1 GB.
