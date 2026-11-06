# 1. Arquitectura y conceptos de Sistemas Operativos y Redes

## Componentes

| Componente | Tecnología | Función |
|---|---|---|
| Infraestructura | VM Oracle Cloud *Always Free* (Ampere A1, ARM64, Ubuntu) | Máquina siempre encendida y gratuita |
| Sistema operativo | Ubuntu Server LTS | Kernel Linux, systemd, firewall, actualizaciones |
| Contenedores | Docker + Docker Compose | Aísla el servidor, lo hace reproducible y fácil de actualizar |
| Servidor de juego | [Paper](https://papermc.io) vía imagen [`itzg/minecraft-server`](https://github.com/itzg/docker-minecraft-server) | Fork de Minecraft con mucho mejor rendimiento que el oficial |
| Backups | [`itzg/mc-backup`](https://github.com/itzg/docker-mc-backup) | Copias periódicas consistentes usando RCON |
| Permisos | LuckPerms | Grupos y permisos (admin, moderador...) |
| Moderación | EssentialsX, CoreProtect | Ban/mute/kick/jail; registro y *rollback* de bloques |
| Diagnóstico | spark (incluido en Paper), Chunky | Medir TPS/lag; pregenerar el mundo |

## Por qué estas decisiones

- **Paper en vez del servidor oficial (vanilla):** vanilla usa un solo hilo para casi todo y con 30 jugadores el TPS cae. Paper optimiza carga de chunks, entidades y redstone, y es compatible con los clientes normales.
- **Docker:** el servidor queda definido en un archivo (`docker-compose.yml`). Reinstalarlo en otra máquina es `git clone` + un script. Actualizar es cambiar la imagen. Si algo se rompe, el sistema anfitrión no se ve afectado.
- **ARM (Ampere A1):** es la única opción gratuita con suficiente RAM. Java y las imágenes usadas son multiarquitectura, así que funciona igual que en x86.

## Conceptos de Sistemas Operativos aplicados

| Concepto | Dónde aparece |
|---|---|
| **Procesos y usuarios** | El servidor corre como UID 1000, no como root (`user: "1000:1000"`). Si alguien explotara una vulnerabilidad, no tendría privilegios de administrador. |
| **Namespaces** | Docker aísla PID, red, montajes y hostname: el proceso de Java no ve los procesos ni archivos del anfitrión. |
| **cgroups** | `mem_limit` y `pids_limit` limitan la RAM y procesos del contenedor: un fallo de memoria no tumba la VM. |
| **Capabilities** | `cap_drop: [ALL]` y `no-new-privileges` quitan incluso los privilegios parciales de root. |
| **Memoria virtual / swap** | Swap de 4 GB con `swappiness=10`: solo se usa ante picos, evitando que el *OOM killer* mate al servidor. |
| **Gestión de memoria de la JVM** | Heap fijo (`-Xms = -Xmx`) y recolector G1 con flags de Aikar: menos pausas de *garbage collection* = menos lag. |
| **Servicios / init** | `systemd` levanta Docker y el servidor al arrancar, aplica el firewall y programa actualizaciones (`.timer`, como cron). |
| **Sistemas de archivos** | Volúmenes *bind mount* (`./data`), montaje de solo lectura para el backup (`:ro`), compresión zstd, rotación de logs. |
| **Señales** | Al detener, Docker envía `SIGTERM`; el servidor avisa en el chat, guarda el mundo y sale (`stop_grace_period: 2m`). |

## Conceptos de Redes aplicados

| Concepto | Dónde aparece |
|---|---|
| **Puertos TCP** | Minecraft Java usa TCP 25565. Es el único puerto de juego publicado. |
| **NAT / port forwarding** | Docker hace DNAT del puerto 25565 del anfitrión al contenedor. Oracle hace NAT 1:1 entre la IP pública y la privada de la VM. |
| **Firewall en capas** | 1) *Security List* de Oracle (firewall de la red virtual), 2) iptables/UFW en la VM, 3) cadena `DOCKER-USER` con límites por IP. |
| **Limitación de tasa** | `connlimit` (conexiones simultáneas por IP) y `hashlimit` (conexiones nuevas por minuto) frenan floods de bots. |
| **Redes internas** | Docker crea una red privada: el contenedor de backup habla con el servidor por RCON (25575) sin que ese puerto salga a internet. |
| **DNS** | Opcional: un subdominio gratuito (DuckDNS) apuntando a la IP pública. |
| **Autenticación** | `online-mode` valida cada cuenta contra los servidores de Microsoft/Mojang; SSH usa criptografía de clave pública. |

## Flujo de una conexión

1. El jugador escribe `IP:25565` en Minecraft.
2. El paquete TCP SYN llega a la IP pública de Oracle → *Security List* lo permite.
3. En la VM, iptables lo pasa por `DOCKER-USER` → `MC-PROTECT` (límites por IP) → DNAT al contenedor.
4. Paper comprueba la cuenta con Microsoft (`online-mode`), luego la whitelist.
5. LuckPerms carga el grupo del jugador (prefijo y permisos).
