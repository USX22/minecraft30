# Resultados de las pruebas (Fase 1: entorno de pruebas)

**Fecha:** 3–4 de noviembre de 2026.
**Dónde:** máquina Linux de pruebas en la nube (4 núcleos x86, 15 GB de RAM) con Docker, ejecutando **el mismo `docker-compose.yml` y los mismos scripts** que se usarán en Oracle.
**Diferencias con producción:** modo *offline* (para que entren bots sin cuenta de Microsoft) y red a través del proxy del entorno de pruebas. Esos ajustes se hicieron en un `docker-compose.override.yml` local que **no** forma parte del repositorio.
**Versiones resueltas automáticamente:** Minecraft **26.1.2**, Paper build 74, imagen `itzg/minecraft-server` (Java 25), LuckPerms 5.5.71, EssentialsX 2.22.0, CoreProtect CE 24.1, Chunky 1.5.3, LPC 4.4.0, ViaVersion/ViaBackwards 5.12.2.

## Resumen

| # | Prueba (tutorial) | Resultado | Detalle |
|---|---|---|---|
| C6 | Instalación con `install.sh` | ✅ | ~3 min en total (descargas, primer arranque, reinicio, roles) |
| C7 | Estado | ✅ | `healthy`, TPS 20.0 |
| D1 | Entrar con un cliente de **otra versión** (26.1 → servidor 26.1.2) | ✅ | ViaVersion/ViaBackwards traducen |
| D3 | Plugins | ✅ | 7 en verde (spark incluido en Paper) |
| E2 | Jugador normal no puede moderar | ✅ | "You do not have access to that command." |
| E3 | Asignar roles moderador/admin | ✅ | `roles.sh info` muestra el grupo |
| E3b | Prefijo de rol en el chat | ✅ | `[Mod] Mod_Test » hola soy moderador` |
| E4a | `/mute` | ✅ | "Your voice has been silenced..." |
| E4b | `/kick` con motivo | ✅ | |
| E4c | `/tempban` impide volver a entrar | ✅ | |
| E4d | `/unban` | ✅ | |
| E5 | Griefing registrado y revertido (CoreProtect) | ✅ | 3 bloques rotos → `/co rollback` los restauró |
| E5b | Moderador no puede sancionar a un admin | ✅ | "You may not mute that player." |
| E6 | Admin no puede hacerse owner ni darse OP | ✅ | |
| F2 | Cuenta fuera de la whitelist rechazada | ✅ | |
| G1 | Caída del proceso (`kill -9`) | ✅ | Volvió solo, `healthy` en **56 s** |
| H4 | Backup → destruir → restaurar | ✅ | Marca de prueba (bloque de oro) recuperada |
| H4b | Restaurar un backup **corrupto** | ✅ | Detectado; el mundo anterior se repuso solo y el servidor siguió `healthy` |
| I | Actualización `update.sh --ahora` | ✅ | Backup + actualización + reinicio en **177 s**, TPS 20.2 |
| J3 | Contenedor sin privilegios | ✅ | `Usuario: 1000:1000`, capabilities `[ALL]` eliminadas |
| J5 | Anti-xray y límites de entidades | ✅ | `anti-xray.enabled: true` |
| K | Carga: 35, 70 y 90 jugadores con **2 núcleos** | ✅ | TPS 19.9–20 en todos los casos |
| — | `MAX_PLAYERS=40` | ✅ | El jugador 41 recibe "Server is full!" |

Las pruebas E/F están automatizadas en `tests/load/roles-test.js` (resultado: **12/12**).

**Quedan para la Fase 2 (Oracle):** firewall real y puertos (J1, J4), SSH (J2), reinicio de la VM (G2), acceso desde distintas redes con el cliente oficial (D1, F) y online-mode con cuentas reales.

## Prueba de carga (servidor limitado a 2 núcleos con `docker update --cpus 2`)

Los bots ([mineflayer](https://github.com/PrismarineJS/mineflayer)) caminan, corren y saltan al azar alrededor del spawn. **MSPT** = milisegundos que tarda cada tick; el máximo para mantener 20 TPS es 50 ms.

**35 jugadores**

| Hora | Jugadores | TPS (1 min) | MSPT | CPU (de 200 %) | RAM contenedor |
|---|---|---|---|---|---|
| 23:57:12 | 35 | 20.0 | 8.4 | 69 % | 8.8 GiB |
| 23:58:15 | 35 | 20.0 | 10.6 | 73 % | 8.9 GiB |
| 23:59:50 | 35 | 20.0 | 9.9 | 52 % | 8.9 GiB |
| 00:00:53 | 35 | 19.6 | 9.9 | 64 % | 8.9 GiB |

**70 jugadores** (con `MAX_PLAYERS` subido temporalmente)

| Hora | TPS | MSPT | CPU |
|---|---|---|---|
| 00:10:38 | 20.0 | 12.4 | 99 % |
| 00:11:42 | 19.8 | 12.8 | 119 % |
| 00:13:17 | 20.0 | 11.7 | 97 % |

**90 jugadores**

| Hora | Jugadores | TPS | MSPT | CPU |
|---|---|---|---|---|
| 00:18:25 | 90 | 20.0 | 12.9 | 136 % |
| 00:19:28 | 90 | 20.0 | 14.7 | 92 % |
| 00:21:04 | 90 | 19.9 | 15.3 | 126 % |

**Interpretación:** con 90 jugadores el servidor usó ~30 % del tiempo disponible por tick. Los jugadores reales cargan más (exploran terreno nuevo, granjas, redstone) y los núcleos ARM de Oracle son algo más lentos, por eso la estimación prudente para uso real es **~50–70 jugadores con 2 OCPU** y **~100 con 4 OCPU**, siempre con el mundo pregenerado.

**104 jugadores (4 núcleos, sin límite)**: TPS 14.3–15.8, MSPT 25–31 ms. **No concluyente**: los 4 procesos de bots corrían en los mismos 4 núcleos que el servidor (carga del sistema de 5,4–6,8 con solo 52 bots), así que el servidor no tenía la CPU completa. Para medir 100 jugadores hay que lanzar los bots desde otra máquina.

> Nota: con más de ~50 bots en un solo proceso, el propio proceso se satura y los bots dejan de enviar su posición; el servidor los expulsa por "flotar" (*Flying is not enabled*). Es la protección anti-trampas funcionando. Por eso `bots.js` admite `BOT_START` para repartir los bots en varios procesos.

## Tamaño del mundo (pregeneración con Chunky, 2 núcleos)

| Medida | Valor |
|---|---|
| Área pregenerada | 2 × 2 km (radio 1000, 16.129 chunks) |
| Tiempo | 16 min 45 s (~16 chunks/s) |
| Disco (mundo normal) | 168 MB |
| Backup comprimido (zstd) | 110 MB |
| Estimación para el tamaño por defecto (6 × 6 km) | ~2 h 30 min, ~1,5 GB, ~1 GB por backup |

## Minecraft Bedrock (Geyser + Floodgate)

| Prueba | Resultado | Detalle |
|---|---|---|
| Geyser y Floodgate cargan | ✅ | Geyser 2.12.1 (b1288), Floodgate 2.2.5 |
| Conexión clásica (RakNet, UDP 19132) | ✅ | Responde al *ping* de Bedrock: `MCPE;Servidor de SO y Redes...;40 plazas` |
| Conexión nueva (NetherNet: señalización TCP 19132 + UDP 19133) | ✅ | Señalización HTTP activa |
| Autenticación por cuenta de Xbox (Floodgate) | ✅ | `auth-type: floodgate` (parche `config/patches/geyser.json`) |
| Whitelist de Bedrock (`whitelist.sh bedrock`) | ✅ | Requiere que el jugador haya intentado entrar una vez |
| Entrar con un cliente Bedrock real | ⏳ | Pendiente para la Fase 2 (Oracle) |

## Errores encontrados y corregidos durante la prueba

| Problema | Impacto | Corrección |
|---|---|---|
| Con `MC_VERSION=LATEST` se eligió Minecraft 26.3, para la que no todos los plugins tenían versión | **El servidor no arrancaba** (bucle de reinicios) | `MC_VERSION_AUTO=true`: se usa la versión más nueva que soportan todos los plugins |
| spark ya no se publica en Modrinth como plugin de Paper | Igual que el anterior | spark viene incluido en Paper: se quitó de la lista |
| `docker compose up` exigía que el servidor estuviera "sano" de inmediato (el backup depende de él) | `install.sh`/`update.sh` fallaban en el primer arranque | Nueva función `start_all`: arranca el servidor, espera y luego el resto |
| Un nick inexistente en `WHITELIST`/`SERVER_OWNER` impide arrancar | Un error de tipeo tumbaba el servidor | `install.sh` verifica cada nick contra Mojang antes de arrancar |
| `roles.sh info`/`lista` no mostraban nada (LuckPerms responde de forma asíncrona y RCON no recibe la respuesta) | Los admins no podían consultar roles | Los comandos se envían a la consola y la respuesta se lee del log |
| `restore.sh` necesitaba `zstd` en la VM; si fallaba dejaba el servidor apagado y sin mundo | Riesgo de pérdida de servicio | Extrae con la imagen de backup y, si algo falla, repone el mundo anterior automáticamente |
| Los archivos de backup se crean con permisos 666 | Cualquier usuario de la VM podía leerlos/modificarlos | Carpeta `backups/` con permisos 2750 (solo servidor y grupo `mcadmin`) |
| `run-load-test.sh` leía mal el número de jugadores (códigos de color) | Resultados de carga incorrectos | Se eliminan los códigos de color antes de leer |
| Geyser publica todas sus versiones como "beta" en Modrinth | Al añadirlo, la elección automática de versión fallaba y el servidor no arrancaba | Geyser y Floodgate se descargan del sitio oficial de GeyserMC |
| Geyser 2.12 usa por defecto solo el método nuevo (NetherNet) y `auth-type: online` | Clientes con el método clásico no conectarían; los de Bedrock necesitarían cuenta de Java | Parche: `transport: both` y `auth-type: floodgate` |
