# Manual completo del servidor Minecraft "minecraft30"

> ¿Quieres instalarlo y probarlo de principio a fin sin leer todo? Sigue el **[TUTORIAL paso a paso](TUTORIAL.md)** y vuelve aquí cuando necesites detalles.

Este manual explica **todo** lo necesario para instalar, usar, moderar, administrar y mantener el servidor, desde cero. Cada concepto técnico se explica antes de usarse. No hace falta experiencia previa.

---

## Índice

0. [Cómo usar este manual (qué leer según tu rol)](#0-cómo-usar-este-manual)
1. [Conceptos técnicos explicados](#1-conceptos-técnicos-explicados)
2. [Cómo funciona este servidor](#2-cómo-funciona-este-servidor)
3. [¿Cuántos jugadores soporta?](#3-cuántos-jugadores-soporta)
4. [Guía del jugador: entrar desde casa o cualquier red](#4-guía-del-jugador)
5. [Guía del moderador](#5-guía-del-moderador)
6. [Guía del administrador del juego](#6-guía-del-administrador-del-juego)
7. [Guía del dueño del servidor](#7-guía-del-dueño-del-servidor)
8. [Administrador de sistema: instalación desde cero](#8-administrador-de-sistema-instalación-desde-cero)
9. [Administrador de sistema: operación y procedimientos](#9-administrador-de-sistema-operación-y-procedimientos)
10. [Mantenimiento programado (listas de control)](#10-mantenimiento-programado)
11. [Respuesta a incidentes](#11-respuesta-a-incidentes)
12. [Modo vanilla: usar el servidor oficial de Mojang](#12-modo-vanilla-servidor-oficial-de-mojang)
13. [Solución de problemas](#13-solución-de-problemas)
14. [Referencia técnica](#14-referencia-técnica)
15. [Preguntas frecuentes](#15-preguntas-frecuentes)

---

## 0. Cómo usar este manual

Hay **cinco tipos de personas** con distintos niveles de acceso. Lee las secciones de tu rol y todas las de los roles inferiores.

| Rol | Qué puede hacer | Dónde trabaja | Leer |
|---|---|---|---|
| **Jugador** | Jugar | Dentro de Minecraft | §1.1, §4 |
| **Moderador** | Mantener el orden: silenciar, expulsar, banear temporalmente, revertir destrozos | Dentro de Minecraft | + §1.7, §5 |
| **Administrador del juego** | Todo lo del juego excepto cambiar roles: bans permanentes, modo creativo, reglas del mundo | Dentro de Minecraft | + §6 |
| **Dueño del servidor** | Además: nombrar moderadores y admins, gestionar permisos | Minecraft (y normalmente también la VM) | + §7 |
| **Administrador de sistema** | Control total de la máquina: instalar, actualizar, backups, seguridad, añadir otros administradores de sistema | Por SSH en la máquina virtual | Todo el manual |

> **Admin del juego ≠ administrador de sistema.** Un admin del juego solo tiene poder *dentro* de Minecraft. Un administrador de sistema controla la *computadora* donde corre el servidor. Normalmente el dueño es también el (primer) administrador de sistema.

**Convenciones del manual:**
- Los bloques grises con `bash` son comandos para escribir en la terminal de la VM (o de tu computadora si se indica). Cópialos tal cual, uno por bloque.
- Los comandos que empiezan con `/` se escriben en el **chat de Minecraft** (tecla `T`).
- `IP_PUBLICA` significa "la dirección IP del servidor" (ej. `129.146.10.20`). Sustitúyela por la real.
- `Nick` significa "nombre de jugador de Minecraft" (ej. `Steve_2005`).

---

## 1. Conceptos técnicos explicados

### 1.1 Minecraft

| Concepto | Explicación |
|---|---|
| **Minecraft: Java Edition** | La versión original de Minecraft para PC (Windows, Mac, Linux). Se compra en minecraft.net y se juega con el *launcher* oficial. **Este servidor es para Java Edition.** |
| **Bedrock Edition** | La versión de móviles (Android/iOS), "Minecraft para Windows" de la Microsoft Store y consolas. Usa otro protocolo, pero **sí puede entrar** a este servidor gracias a Geyser y Floodgate (§4.7). |
| **Geyser** | Plugin que traduce en tiempo real el protocolo de Bedrock al de Java, para que jugadores de ambas ediciones compartan el mismo mundo. |
| **Floodgate** | Plugin que deja entrar a los jugadores de Bedrock con su cuenta de Xbox/Microsoft, sin necesitar comprar Java. Sus nombres llevan un punto delante: `.Gamertag`. |
| **Gamertag** | El nombre de la cuenta de Xbox/Microsoft de un jugador de Bedrock. Si tiene espacios, en el servidor se convierten en `_` (ej. `Cool Guy` → `.Cool_Guy`). |
| **Cliente** | El juego que cada jugador tiene en su computadora. |
| **Servidor** | Un programa que guarda el mundo y sincroniza a todos los clientes. No tiene gráficos; corre en una máquina remota. |
| **Versión / protocolo** | Cada versión de Minecraft (1.20.4, 1.21.4...) habla un "idioma" de red ligeramente distinto. Normalmente cliente y servidor deben tener la misma versión. Aquí ViaVersion/ViaBackwards traducen entre versiones (ver §4.3). |
| **Cuenta oficial / premium** | Cuenta de Microsoft con Minecraft comprado. El servidor verifica con Microsoft que la cuenta es real (*online-mode*). Los *launchers* piratas (TLauncher, etc.) **no** pueden entrar. |
| **Vanilla** | El servidor oficial de Mojang, sin modificar. |
| **Paper** | Un servidor alternativo, compatible con el cliente oficial, que ejecuta el mismo juego pero mucho más optimizado y admite *plugins*. Es el que usamos por defecto. El jugador **no nota diferencia** ni necesita instalar nada. |
| **Plugin** | Extensión que se instala **solo en el servidor** y añade funciones (permisos, comandos de moderación...). Los jugadores no instalan nada. |
| **Mod** | Modificación que normalmente requiere que el *cliente* también la instale (Forge/Fabric). **Este servidor no usa mods**, solo plugins. |
| **Whitelist** | Lista de nicks autorizados. Si no estás en ella, el servidor te rechaza con *"You are not whitelisted on this server"*. |
| **OP (operador)** | Permiso de "superusuario" de Minecraft vanilla. Es "todo o nada" (niveles 1–4). Aquí solo el dueño es OP; el resto usa roles (ver §1.7). |
| **Mundo, dimensiones** | El mundo tiene tres dimensiones: Overworld (normal), Nether y End. Se guardan en `data/world`, `data/world_nether`, `data/world_the_end`. |
| **Chunk** | El mundo se divide en columnas de 16×16 bloques llamadas *chunks*. El servidor solo simula los chunks cercanos a jugadores. |
| **Generar / pregenerar** | La primera vez que alguien visita una zona, el servidor *genera* el terreno (muy costoso). *Pregenerar* = generarlo todo antes de que entren jugadores. |
| **View distance** | Radio de chunks que el servidor envía a cada jugador (8 = 8 chunks = 128 bloques en cada dirección). |
| **Simulation distance** | Radio en el que los chunks están "vivos" (cultivos crecen, mobs se mueven). |
| **Tick / TPS** | El servidor actualiza el mundo 20 veces por segundo; cada actualización es un *tick*. **TPS** = ticks por segundo. 20 = perfecto; menos de 15 = lag. |
| **Lag** | Retraso. Puede ser de **red** (ping alto, culpa de la conexión) o de **servidor** (TPS bajo, el servidor no da abasto). |
| **Ping / latencia** | Tiempo que tarda un paquete en ir y volver del servidor, en milisegundos. < 100 ms es bueno. |
| **Griefing** | Destruir o robar construcciones ajenas a propósito. |
| **EULA** | Acuerdo de licencia de Mojang que el dueño del servidor acepta (`EULA: TRUE`). Prohíbe, entre otras cosas, vender ventajas de juego. |

### 1.2 Redes

| Concepto | Explicación |
|---|---|
| **Dirección IP** | El "número de teléfono" de una máquina en una red. IPv4: cuatro números, ej. `129.146.10.20`. |
| **IP pública** | La IP visible desde todo internet. El servidor tiene una fija: **cualquiera, desde cualquier red, puede llegar a ella**. |
| **IP privada** | IP solo válida dentro de una red local (ej. `10.0.0.5`, `192.168.1.10`). La VM tiene una privada; Oracle traduce la pública a la privada. |
| **Puerto** | Número (0–65535) que identifica *qué programa* dentro de una máquina recibe la conexión. Si la IP es el edificio, el puerto es el número de departamento. Minecraft Java usa **25565**. SSH usa **22**. |
| **TCP** | Protocolo de transporte fiable (reenvía paquetes perdidos, mantiene el orden). Minecraft Java usa TCP. |
| **UDP** | Protocolo de transporte sin conexión: más rápido, pero no garantiza la entrega. Minecraft Bedrock usa UDP (con su propio sistema de fiabilidad, RakNet). Hay que abrir los puertos UDP aparte de los TCP. |
| **RakNet / NetherNet** | Los dos métodos de conexión de Bedrock: RakNet es el clásico (UDP 19132); NetherNet es el nuevo, basado en WebRTC (señalización por TCP 19132 + datos por UDP 19133). El servidor acepta ambos. |
| **STUN** | Servicio que le dice a un servidor cuál es su IP pública vista desde internet. Geyser lo usa para NetherNet. |
| **NAT** | *Network Address Translation*: un router hace que muchas máquinas con IP privada salgan a internet con **una sola IP pública**. Ej.: todos los alumnos en la red de la universidad aparecen con la misma IP. Importante para los límites por IP y para no banear IPs (ver §6.4). |
| **CG-NAT** | NAT del proveedor de internet: tu casa no tiene IP pública propia. No afecta a los **jugadores** (solo salen hacia el servidor), sí a quien quiera *alojar* un servidor en casa. |
| **Port forwarding / DNAT** | Redirigir un puerto de una IP a otra máquina/puerto. Docker redirige el 25565 de la VM al contenedor. |
| **Firewall** | Filtro que decide qué conexiones se aceptan según IP, puerto y protocolo. Aquí hay tres capas (ver §2.3). |
| **iptables / UFW** | Herramientas de Linux para configurar el firewall del kernel. UFW es una interfaz simplificada de iptables. |
| **Security List** | El firewall de la red virtual de Oracle, *fuera* de la VM. Hay que abrir el puerto ahí **y** en la VM. |
| **`0.0.0.0/0`** | Notación CIDR que significa "cualquier dirección IP". Una regla con origen `0.0.0.0/0` permite conexiones **desde cualquier lugar** (casas, universidades, datos móviles). |
| **DNS** | Sistema que traduce nombres (`miserver.duckdns.org`) a IPs. Permite dar un nombre fácil en vez de la IP. |
| **DDoS / flood** | Ataque que satura el servidor con muchísimas conexiones. Los límites de conexiones por IP mitigan ataques pequeños. |
| **VPN** | Red privada cifrada. **No hace falta** para jugar en este servidor. |

### 1.3 Sistema operativo y Linux

| Concepto | Explicación |
|---|---|
| **Máquina virtual (VM)** | Una computadora simulada dentro de un servidor físico de un centro de datos. Para nosotros se comporta como una computadora real con Linux, siempre encendida. |
| **Nube / Oracle Cloud** | Empresa que alquila (o regala, en el plan *Always Free*) máquinas virtuales. |
| **OCPU / vCPU** | Núcleos de procesador asignados a la VM. En Oracle ARM, 1 OCPU = 1 núcleo físico. |
| **ARM / Ampere** | Arquitectura de procesador (la misma familia que los móviles y los Mac M1). Java y Docker funcionan igual que en Intel/AMD. |
| **RAM** | Memoria de trabajo. El servidor guarda allí los chunks cargados, entidades y jugadores. |
| **Disco / boot volume** | Almacenamiento permanente: sistema operativo, mundo y backups. |
| **Swap** | Espacio del disco usado como RAM de emergencia. Es lento, pero evita que el sistema mate procesos si la RAM se llena. |
| **OOM killer** | Mecanismo del kernel que mata un proceso cuando se acaba la memoria. Los límites de memoria y el swap lo evitan. |
| **Linux / Ubuntu** | Sistema operativo de la VM. Ubuntu Server no tiene escritorio: se controla con texto. |
| **Kernel** | El núcleo del sistema operativo: gestiona procesos, memoria, red, firewall. |
| **Terminal / shell / bash** | Programa donde se escriben comandos de texto. `bash` es el intérprete de comandos. |
| **Script (`.sh`)** | Archivo con una lista de comandos que se ejecutan en orden. Los de `scripts/` automatizan todas las tareas. |
| **Usuario y grupo** | Cada persona/programa es un *usuario* con un número (UID). Los *grupos* agrupan usuarios para darles permisos comunes (ej. `docker`, `mcadmin`). |
| **root / sudo** | `root` es el superusuario (puede hacer todo). `sudo` ejecuta *un* comando como root, pidiendo autorización. Solo se usa cuando es necesario. |
| **Permisos de archivo** | Cada archivo indica quién puede leerlo/escribirlo/ejecutarlo: el dueño, el grupo, el resto. Ej. `.env` es `640`: dueño lee/escribe, grupo `mcadmin` lee, el resto nada. |
| **Proceso** | Programa en ejecución. El servidor de Minecraft es un proceso de Java. |
| **Señal SIGTERM** | Aviso que el sistema envía a un proceso para que termine ordenadamente. Minecraft la usa para guardar el mundo antes de cerrarse. |
| **systemd / servicio** | El programa que arranca todo al encender la VM. Un *servicio* (`.service`) es un programa gestionado por systemd. |
| **Timer** | Un `.timer` de systemd ejecuta un servicio en un horario (como una alarma). Aquí: actualización cada lunes 05:00. |
| **cron** | Alternativa clásica a los timers para tareas programadas. |
| **Logs / journal** | Registros de lo que hace cada programa. `journalctl` muestra los de systemd; `docker compose logs` los de los contenedores. |
| **Paquete / apt** | `apt` instala y actualiza software en Ubuntu. |
| **unattended-upgrades** | Servicio que instala automáticamente las actualizaciones de seguridad de Ubuntu. |
| **Editor `nano`** | Editor de texto de la terminal. Se abre con `nano archivo`. **Guardar:** `Ctrl+O` y luego `Enter`. **Salir:** `Ctrl+X`. **Buscar:** `Ctrl+W`. |
| **Java / JVM** | Minecraft está escrito en Java. La **JVM** (Java Virtual Machine) es el programa que lo ejecuta. |
| **Heap** | La parte de la RAM que la JVM usa para los datos del juego. Se configura con `MC_MEMORY`. |
| **Garbage collector (GC)** | Parte de la JVM que libera memoria que ya no se usa. Si está mal ajustado produce "tirones" de lag. Usamos los ajustes de Aikar, recomendados para Minecraft. |

### 1.4 Seguridad

| Concepto | Explicación |
|---|---|
| **SSH** | *Secure Shell*: protocolo para controlar la VM remotamente por terminal, con todo el tráfico cifrado. Puerto 22. |
| **Par de llaves SSH** | Dos archivos generados juntos: la **llave privada** (se queda en tu computadora, **nunca se comparte**, es como la llave de tu casa) y la **llave pública** (`.pub`, se pone en el servidor, es como la cerradura). Solo quien tiene la privada puede entrar. Es mucho más seguro que una contraseña. |
| **Fuerza bruta** | Probar miles de contraseñas hasta acertar. Imposible contra llaves SSH. |
| **fail2ban** | Programa que lee los logs y bloquea temporalmente las IPs que fallan repetidamente al entrar por SSH. |
| **online-mode** | El servidor pregunta a Microsoft si la cuenta que intenta entrar es auténtica. Impide suplantar a otro jugador (por ejemplo, entrar como el dueño). |
| **RCON** | *Remote Console*: protocolo para enviar comandos de consola al servidor. Protegido por contraseña y **no expuesto a internet**: solo los scripts dentro de la VM lo usan. |
| **Inmunidad (exempt)** | Los admins, el dueño y los OP tienen permisos `*.exempt`: un moderador no puede silenciarlos, expulsarlos ni banearlos. |
| **Mínimo privilegio** | Dar a cada persona/programa solo los permisos estrictamente necesarios. |
| **Escalada de privilegios** | Que alguien con pocos permisos consiga más (ej. un moderador que se hace admin). Los roles están diseñados para impedirlo. |
| **Anti-xray** | Función de Paper que oculta los minerales a los clientes, de modo que un *hack* de x-ray (ver a través de bloques) no sirve. |
| **Secreto** | Contraseña o llave. Aquí: la contraseña RCON (en `.env`) y las llaves privadas SSH. Nunca se suben a git ni se envían por chat. |
| **Defensa en profundidad** | Varias capas de protección independientes; si una falla, las demás siguen. |

### 1.5 Docker y contenedores

| Concepto | Explicación |
|---|---|
| **Contenedor** | Un proceso aislado que ve su propio sistema de archivos, red y procesos, como una "mini-máquina" ligera. El servidor de Minecraft corre en el contenedor `mc` y los backups en `mc-backup`. |
| **Imagen** | La "plantilla" de la que se crea un contenedor (incluye Java y los scripts de arranque). Usamos `itzg/minecraft-server` e `itzg/mc-backup`, mantenidas por la comunidad. Actualizar = descargar una imagen nueva y recrear el contenedor. |
| **Docker** | El programa que descarga imágenes y ejecuta contenedores. |
| **Docker Compose** | Herramienta que lee `docker-compose.yml` (la descripción de todos los contenedores) y los levanta juntos con `docker compose up -d`. |
| **Volumen / bind mount** | Carpeta de la VM conectada dentro del contenedor. `./data` (en la VM) = `/data` (en el contenedor). Así el mundo **sobrevive** aunque se borre el contenedor. |
| **`restart: unless-stopped`** | Si el contenedor se cae, o se reinicia la VM, Docker lo vuelve a arrancar solo. |
| **Healthcheck** | Comprobación periódica de que el servidor responde. Estados: `starting` (arrancando), `healthy` (bien), `unhealthy` (no responde). |
| **namespaces, cgroups, capabilities** | Mecanismos del kernel que usa Docker: *namespaces* aíslan lo que ve el proceso, *cgroups* limitan cuánta RAM/CPU usa, *capabilities* son "trozos" de los poderes de root (aquí se quitan todos). |
| **`.env`** | Archivo con la configuración y secretos que lee Docker Compose (memoria, versión, contraseña RCON...). |
| **override** | `docker-compose.override.yml`: archivo opcional, no versionado, para personalizaciones locales que Compose combina con el principal. |

### 1.6 Rendimiento

| Concepto | Explicación |
|---|---|
| **Hilo principal** | Minecraft simula el mundo en **un único hilo** (un núcleo). Por eso la velocidad de *cada* núcleo importa más que el número de núcleos. Los demás núcleos se usan para generar terreno, red, guardar y el GC. |
| **Entidades** | Todo lo que se mueve: mobs, animales, ítems en el suelo, flechas. Muchas entidades juntas (granjas) bajan el TPS. |
| **spark** | Herramienta (incluida dentro de Paper) que mide qué consume tiempo en cada tick (para encontrar la causa del lag). |
| **Chunky** | Plugin que pregenera el mundo. |
| **World border** | Borde del mundo: límite que impide ir más lejos y, por tanto, generar terreno nuevo. |

### 1.7 Permisos y roles (LuckPerms)

| Concepto | Explicación |
|---|---|
| **LuckPerms** | Plugin que gestiona permisos por grupos. |
| **Permiso / nodo** | Texto que autoriza una acción concreta, ej. `essentials.kick` (usar `/kick`). Puede estar en `true` (permitido) o `false` (denegado). |
| **Comodín `*`** | "Todos los permisos". Un permiso explícito en `false` gana al comodín: así el admin tiene `*` pero no `luckperms.*`. |
| **Grupo / rol** | Conjunto de permisos con nombre: `default`, `moderador`, `admin`, `owner`. Cada jugador pertenece a uno. |
| **Herencia (parent)** | Un grupo incluye los permisos de su "padre": `owner` ⊃ `admin` ⊃ `moderador` ⊃ `default`. |
| **Peso (weight)** | Prioridad del grupo (0, 50, 90, 100). Decide qué prefijo se muestra y quién "gana" en conflictos. |
| **Prefijo** | Etiqueta en el chat: `[Mod]`, `[Admin]`, `[Dueño]`. La muestra el plugin **LPC**, que usa el formato de colores *MiniMessage* (ej. `<blue>[Mod]</blue> `). |
| **EssentialsX** | Plugin que añade los comandos de moderación (`/mute`, `/tempban`, `/jail`...) y de jugador (`/home`, `/tpa`...). |
| **CoreProtect** | Plugin que registra **cada** bloque colocado/roto y cada cofre abierto, con quién y cuándo, y permite deshacerlo (*rollback*). |

### 1.8 Backups y actualizaciones

| Concepto | Explicación |
|---|---|
| **Backup** | Copia del mundo y la configuración en un momento dado. Aquí: cada 6 h, en `backups/`, comprimido con **zstd** (formato `.tar.zst`). |
| **Backup consistente** | Copia hecha mientras el servidor *no* está escribiendo (se pausa el guardado con `save-off`), para que no quede a medias. |
| **Retención / prune** | Cuánto tiempo se guardan los backups antes de borrarse (7 días). |
| **Restaurar** | Volver el mundo al estado de un backup. |
| **Regla 3-2-1** | 3 copias, en 2 medios distintos, 1 fuera del sitio. Por eso se recomienda copiar los backups fuera de la VM (§9.8). |
| **Rollback (CoreProtect)** | Deshacer los cambios de un jugador en una zona y tiempo concretos **sin** afectar al resto del mundo. Preferible a restaurar un backup. |
| **Build de Paper** | Pequeñas actualizaciones de Paper dentro de una misma versión de Minecraft (correcciones). Se aplican solas en cada reinicio. |

### 1.9 Git y el repositorio

| Concepto | Explicación |
|---|---|
| **Git** | Sistema de control de versiones: guarda el historial de cambios de los archivos del proyecto. |
| **Repositorio** | La carpeta del proyecto con su historial. Está en GitHub (`usx22/minecraft30`) y una copia en la VM (`/opt/minecraft30`). |
| **clone / pull** | `git clone` descarga el repositorio por primera vez; `git pull` trae los cambios nuevos. `update.sh` hace `git pull` cada semana. |
| **commit / push** | Guardar un cambio en el historial / subirlo a GitHub. |
| **`.gitignore`** | Lista de archivos que git ignora: `.env`, `data/`, `backups/` (secretos y datos nunca se suben). |
| **CI (GitHub Actions)** | Comprobaciones automáticas que GitHub ejecuta en cada cambio (sintaxis, scripts, que no se suban secretos). |

---

## 2. Cómo funciona este servidor

### 2.1 Vista general

```
   Jugadores (casas, universidad, datos móviles: CUALQUIER IP)
                 │  Java oficial  → IP_PUBLICA:25565 (TCP)
                 │  Bedrock       → IP_PUBLICA:19132 (UDP; NetherNet: TCP 19132 + UDP 19133)
                 ▼
 ┌─ Oracle Cloud ─────────────────────────────────────────────────────┐
 │  Security List: 22, 25565, 19132-19133 desde 0.0.0.0/0 (cualq. IP)  │
 │ ┌─ VM Ubuntu ────────────────────────────────────────────────────┐ │
 │ │ Firewall (iptables/UFW) + anti-flood por IP (MC-PROTECT)        │ │
 │ │ SSH (22): solo llaves + fail2ban  ◄── administradores de sistema│ │
 │ │                                                                 │ │
 │ │  Docker                                                         │ │
 │ │   ├─ mc        Paper + plugins (LuckPerms, EssentialsX,         │ │
 │ │   │            CoreProtect, Chunky, LPC, ViaVersion, Geyser,    │ │
 │ │   │            Floodgate) + spark                               │ │
 │ │   │            usuario sin privilegios, RAM limitada            │ │
 │ │   └─ mc-backup cada 6 h → backups/*.tar.zst (vía RCON interno)  │ │
 │ │                                                                 │ │
 │ │  systemd: minecraft.service (arranque) · minecraft-firewall ·   │ │
 │ │           minecraft-update.timer (lunes 05:00)                  │ │
 │ │  /opt/minecraft30: data/ (mundo) · backups/ · scripts/ · .env   │ │
 │ └─────────────────────────────────────────────────────────────────┘ │
 └─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Qué pasa cuando un jugador se conecta
1. El jugador pone la dirección en Minecraft. Si es un nombre, el DNS lo traduce a la IP.
2. Su conexión TCP sale de su casa (vía el NAT de su router) hacia `IP_PUBLICA:25565`.
3. La *Security List* de Oracle la deja pasar (origen `0.0.0.0/0`).
4. En la VM, el firewall comprueba que esa IP no supere 40 conexiones simultáneas ni ~60 nuevas por minuto.
5. Docker la redirige al contenedor `mc`.
6. ViaVersion detecta la versión del cliente y traduce si hace falta.
7. Paper pregunta a Microsoft si la cuenta es auténtica (*online-mode*).
8. Paper comprueba la whitelist.
9. LuckPerms carga su grupo (permisos y prefijo). El jugador aparece en el mundo.

Un jugador de **Bedrock** entra por el puerto 19132: Geyser recibe la conexión, Floodgate comprueba su cuenta de Xbox/Microsoft y le asigna el nombre `.Gamertag`, y a partir de ahí sigue los pasos 8–9 como cualquier jugador de Java (whitelist y roles).

### 2.3 Capas de seguridad (resumen)
1. Firewall de Oracle → 2. Firewall de la VM → 3. Anti-flood por IP → 4. SSH solo con llave + fail2ban → 5. Actualizaciones automáticas de Ubuntu → 6. Contenedor sin privilegios → 7. online-mode → 8. Whitelist → 9. Roles con mínimo privilegio → 10. Anti-xray → 11. CoreProtect + backups para recuperarse. Detalle en [03-seguridad.md](03-seguridad.md).

### 2.4 Funcionamiento continuo (24/7)
- Si el proceso de Minecraft falla, Docker lo reinicia (`restart: unless-stopped`).
- Si la VM se reinicia (actualizaciones de Ubuntu, mantenimiento de Oracle), systemd arranca Docker y Docker arranca los contenedores.
- La autopausa está desactivada: el servidor nunca "se duerme", aunque no haya nadie.
- La única interrupción planificada es el reinicio semanal de actualización (lunes ~05:00, 1–3 minutos, con aviso).

---

## 3. ¿Cuántos jugadores soporta?

**¿Y 100 jugadores?** Es posible con la VM de **4 OCPU / 24 GB** (si tu cuota la permite), con el mundo pregenerado y algo menos de distancia de visión (`VIEW_DISTANCE=7`, `SIMULATION_DISTANCE=5`), subiendo `MAX_PLAYERS=100`. Con 2 OCPU no se recomienda: 100 jugadores reales explorando es demasiado. La prueba con 104 bots en la máquina de pruebas (4 núcleos) dio ~14,5 TPS, pero ahí los propios bots consumían la mitad de la CPU, así que no es concluyente: hay que medirlo en Oracle lanzando los bots desde **otra** máquina (§3.3).

**Respuesta corta:** en la prueba de carga real de este proyecto, con el servidor **limitado a 2 núcleos** (como la VM gratuita de 2 OCPU), **90 bots conectados a la vez mantuvieron 20 TPS** (cada tick tardó ~15 ms de los 50 ms disponibles). Con 35 bots, ~10 ms. Los bots se mueven al azar pero no exploran lejos ni construyen granjas, y los núcleos ARM de Oracle son algo más lentos que los de la prueba, así que la **estimación prudente para jugadores reales es ~50–70 con 2 OCPU / 12 GB y ~100 con 4 OCPU / 24 GB**, con el mundo pregenerado. Los 30 requeridos tienen mucho margen. Resultados completos en [RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md).

| Máquina | Paper (por defecto) | Vanilla (oficial, §12) |
|---|---|---|
| Prueba real, 2 núcleos, 8 GB (bots) | **90 con TPS 20** (medido) | — |
| Oracle 2 OCPU / 12 GB (`MC_MEMORY=8G`) | ~50–70 (estimado) | ~20–30 (estimado) |
| Oracle 4 OCPU / 24 GB (`MC_MEMORY=12G`) | ~100 (estimado) | ~30–40 (estimado) |

`MAX_PLAYERS=40` en `.env` es solo el **límite de admisión** (el jugador 41 ve "servidor lleno"). Puedes subirlo si las pruebas lo respaldan (§9.5).

### 3.1 De qué depende
- **Velocidad de un núcleo** (hilo principal, §1.6): lo que más limita.
- **Exploración de terreno nuevo:** generar chunks es lo más costoso. Pregenerar (§8.13) multiplica la capacidad.
- **Distancia de visión:** con `VIEW_DISTANCE=8` cada jugador mantiene (2·8+1)² = 289 chunks; con 12, 625 (más del doble de trabajo).
- **Granjas y entidades:** 30 jugadores con granjas de mobs gigantes pueden bajar el TPS más que 60 jugadores construyendo.
- **RAM:** con 8 GB de heap la prueba con 90 bots no necesitó más memoria (el contenedor se mantuvo en ~8,8 GB).
- **Red:** ~50–150 kbit/s por jugador → 30 jugadores ≈ 5 Mbit/s; la VM tiene ≥ 1 Gbit/s.

### 3.2 Por qué Paper soporta más que vanilla
Paper carga chunks en paralelo, optimiza entidades, redstone, IA de mobs e iluminación, y limita acumulaciones. El juego es el mismo para el jugador.

### 3.3 Cómo medirlo
Ver [06-rendimiento.md](06-rendimiento.md): `./tests/load/run-load-test.sh 50` conecta 50 bots que se mueven al azar y guarda el TPS cada 30 s en `tests/load/resultados.csv`. Mientras el TPS se mantenga ≥ 19, el servidor aguanta esa cantidad.

---

## 4. Guía del jugador

### 4.1 Requisitos
- **Minecraft: Java Edition oficial** comprado (cuenta de Microsoft), con el *launcher* oficial de minecraft.net. Funciona en Windows, Mac y Linux.
- Que un moderador/admin haya añadido tu **nick exacto** a la whitelist. Envíaselo tal cual aparece en el launcher (mayúsculas incluidas).
- **No necesitas**: instalar mods, abrir puertos en tu router, VPN, ni estar en la universidad. Puedes entrar **desde tu casa, la universidad, datos móviles o cualquier red** con internet.

### 4.2 Entrar por primera vez
1. Abre el launcher oficial e inicia sesión con tu cuenta de Microsoft.
2. Elige la versión (ver §4.3) y pulsa **Jugar**.
3. Menú principal → **Multijugador** → **Agregar servidor**.
4. **Nombre del servidor:** el que quieras (ej. "Servidor de Redes").
5. **Dirección del servidor:** la IP o el nombre que te den (ej. `129.146.10.20` o `miserver.duckdns.org`). No hace falta poner `:25565`.
6. **Listo** → selecciona el servidor → **Unirse al servidor**.

### 4.3 ¿Qué versión de Minecraft uso?
- Lo ideal: **la misma versión que el servidor** (aparece al pasar el ratón por el icono de señal en la lista de servidores, o pregúntala al admin).
- Gracias a ViaVersion/ViaBackwards también puedes entrar con versiones **más nuevas** y con bastantes versiones **anteriores** del cliente oficial. Si ves *"Outdated client"* o *"Incompatible version"*, usa la versión del servidor:
  Launcher → **Instalaciones** → **Nueva instalación** → elige la versión → **Crear** → selecciónala en **Jugar**.
- En modo vanilla (§12) la versión debe ser **exactamente** la del servidor.

### 4.4 Comandos de jugador

| Comando | Qué hace |
|---|---|
| `/sethome` · `/sethome nombre` | Guarda tu posición como "casa" |
| `/home` · `/home nombre` | Te teletransporta a tu casa |
| `/delhome nombre` | Borra una casa |
| `/spawn` | Vuelve al punto de aparición |
| `/back` | Vuelve al lugar donde estabas antes de teletransportarte o morir |
| `/tpa Nick` | Pide teletransportarte hacia otro jugador |
| `/tpaccept` · `/tpdeny` | Acepta/rechaza una petición de teletransporte |
| `/msg Nick texto` · `/r texto` | Mensaje privado / responder |
| `/mail send Nick texto` · `/mail read` | Correo para jugadores desconectados |
| `/ignore Nick` | Dejar de ver los mensajes de alguien |
| `/helpop texto` | Mensaje que **solo ven los moderadores** (para pedir ayuda o denunciar) |
| `/afk` | Marcarte como ausente |
| `/rules` | Ver las reglas |
| `/list` | Ver quién está conectado |
| `/seen Nick` | Cuándo se conectó por última vez alguien |

### 4.5 Problemas comunes del jugador

| Mensaje | Causa y solución |
|---|---|
| *You are not whitelisted on this server* | Tu nick no está en la whitelist. Pide que te añadan (con el nick exacto). |
| *Failed to verify username* / *Invalid session* | Problema de sesión con Microsoft. Cierra el juego y el launcher, vuelve a iniciar sesión. |
| *Connection timed out* | Tu red bloquea el puerto 25565 (pasa en algunas redes de empresa/colegio) o el servidor está caído. Prueba con datos móviles; si con datos funciona, pide al admin el puerto alternativo (§9.13). Si tampoco, avisa al admin. |
| *Connection refused* | El servidor se está reiniciando. Espera 2–3 minutos. |
| *Outdated client / server* | Versión distinta (§4.3). |
| *You are banned* | Contacta a un admin por el medio acordado por la clase. |
| Lag con ping alto | Problema de tu conexión (Wi-Fi débil, descargas). |
| Lag con bloques que reaparecen y mobs a saltos | Lag del servidor: avisa con `/helpop`. |

Para comprobar si tu red bloquea el puerto (desde tu computadora, no desde Minecraft):
- **Windows (PowerShell):** `Test-NetConnection IP_PUBLICA -Port 25565` → debe decir `TcpTestSucceeded : True`.
- **Mac/Linux (Terminal):** `nc -vz IP_PUBLICA 25565` → debe decir `succeeded` u `open`.

### 4.6 Normas básicas
No destruyas ni robes construcciones ajenas, no uses hacks (x-ray, fly, kill-aura), respeta en el chat. Todo queda registrado (CoreProtect) y puede revertirse.

### 4.7 Entrar desde Minecraft Bedrock (móvil, Windows, consolas)
Requisitos: Minecraft Bedrock comprado y una **cuenta de Xbox/Microsoft** (gratuita). No hace falta comprar la edición Java.

1. Envía tu **gamertag** exacto a un administrador (aparece en la pantalla principal de Minecraft, arriba a la derecha).
2. **Intenta entrar una vez** (pasos 3–5). Te rechazará con un mensaje de whitelist: es normal, así el servidor conoce tu cuenta. Avisa al administrador para que te añada (§9.4) y vuelve a entrar.
3. **Jugar → Servidores → Agregar servidor** (al final de la lista de servidores).
4. **Nombre:** el que quieras. **Dirección:** `IP_PUBLICA` (o el dominio). **Puerto:** `19132`.
5. **Guardar** y pulsa el servidor para entrar.

Dentro del juego tu nombre aparece con un punto delante (`.TuGamertag`); si tiene espacios, se cambian por `_`. Juegas en el **mismo mundo** que los jugadores de Java y los comandos (`/home`, `/tpa`...) son iguales.

**Consolas (Xbox, PlayStation, Switch):** no permiten añadir servidores externos desde el menú. Hay soluciones de la comunidad (por ejemplo, *BedrockConnect*, que se configura cambiando el DNS de la consola), pero quedan fuera de este manual. En **Android, iOS y Windows** funciona directamente.

**Diferencias para jugadores de Bedrock:** algunas mecánicas muy concretas de Java (ciertos trucos de redstone o de combate) pueden comportarse distinto, porque el juego que corre es el de Java.

---

## 5. Guía del moderador

Tu trabajo: mantener la convivencia, responder a `/helpop` y reparar destrozos. Tienes prefijo `[Mod]`.

### 5.1 Formato de tiempos
Muchos comandos aceptan duraciones: `30s` (segundos), `10m` (minutos), `2h` (horas), `1d` (días), `1w` (semanas). Se pueden combinar: `1h30m`.

### 5.2 Protocolo de sanciones (recomendado)
Aplica la sanción **mínima** que resuelva el problema y **escribe siempre el motivo** (queda registrado).

| Gravedad | Ejemplo | Acción |
|---|---|---|
| Leve | Spam, lenguaje inapropiado | Aviso por `/msg` → si repite, `/mute Nick 10m motivo` |
| Media | Insultos, molestar a otros | `/mute Nick 1h` o `/kick Nick motivo` |
| Grave | Griefing, robo | Investigar con CoreProtect (§5.4) → revertir → `/tempban Nick 1d motivo` → avisar a un admin |
| Muy grave | Hacks, griefing masivo, reincidencia | `/tempban Nick 7d motivo` y avisar a un admin (puede convertirlo en permanente) |

### 5.3 Comandos de moderación

| Comando | Qué hace |
|---|---|
| `/kick Nick motivo` | Expulsa (puede volver a entrar) |
| `/mute Nick 10m motivo` | Silencia en el chat por un tiempo; `/mute Nick` de nuevo lo quita |
| `/tempban Nick 1d motivo` | Ban temporal |
| `/unban Nick` | Quita un ban |
| `/jail Nick carcel 30m` | Encierra en una cárcel (un admin debe haberla creado con `/setjail carcel`); `/unjail Nick` lo libera |
| `/jails` | Lista de cárceles |
| `/tp Nick` · `/tphere Nick` | Ir hacia un jugador / traerlo |
| `/vanish` | Hacerte invisible (para observar sin ser visto). Repetir para volver a ser visible |
| `/gamemode spectator` · `/gamemode survival` | Modo espectador (atravesar paredes, volar) / volver al normal |
| `/invsee Nick` | Ver el inventario de un jugador |
| `/whois Nick` · `/seen Nick` | Información de un jugador y última conexión |
| `/socialspy` | Ver los mensajes privados (úsalo solo para investigar acosos; respeta la privacidad) |
| `/broadcast texto` | Anuncio a todo el servidor |
| `/whitelist add Nick` · `/whitelist remove Nick` | Gestionar la whitelist |
| `/tps` · `/spark healthreport` | Ver el rendimiento del servidor |

Los mensajes de `/helpop` de los jugadores te aparecen en el chat.

### 5.4 Investigar y reparar griefing con CoreProtect

Parámetros: `u:` usuario · `t:` tiempo atrás · `r:` radio en bloques alrededor de ti · `a:` acción (`block`, `+block` colocados, `-block` rotos, `container` cofres).

1. **Ve al lugar** del destrozo (`/tp`).
2. **Inspecciona**: `/co i` activa el inspector. Haz clic izquierdo en un bloque para ver quién lo rompió/colocó y cuándo; clic derecho en un cofre para ver quién sacó o metió cosas. `/co i` de nuevo lo desactiva.
3. **Busca todo lo que hizo** el sospechoso cerca: `/co lookup u:Nick t:3h r:30`. Pasa de página con `/co page 2`.
4. **Revierte**: `/co rollback u:Nick t:3h r:30`. Revisa el resultado.
   - Solo cofres: `/co rollback u:Nick t:3h r:30 a:container`
5. **Si te equivocaste**: `/co undo` (deshace tu último rollback) o `/co restore u:Nick t:3h r:30`.
6. Sanciona (§5.2) y deja constancia del motivo.

> Usa siempre el **radio y tiempo mínimos** necesarios. Un rollback sin `u:` revertiría lo de **todos** los jugadores.

### 5.5 Lo que un moderador NO puede hacer
Bans permanentes, modo creativo, darse objetos, cambiar reglas del mundo, nombrar moderadores. Tampoco sancionar a admins ni al dueño (son inmunes). Para eso, avisa a un admin o al dueño.

---

## 6. Guía del administrador del juego

Tienes prefijo `[Admin]` y **todos** los permisos del juego excepto: gestionar roles (LuckPerms), dar/quitar OP. Así nadie puede auto-ascenderse.

### 6.1 Comandos de administración

| Comando | Qué hace |
|---|---|
| `/ban Nick motivo` | Ban permanente |
| `/gamemode creative` · `/gamemode survival` | Modo creativo / supervivencia |
| `/give Nick objeto cantidad` | Dar objetos (úsalo solo para compensar pérdidas) |
| `/setspawn` | Fija el punto de aparición donde estás |
| `/setjail nombre` · `/deljail nombre` | Crea/borra una cárcel donde estás |
| `/setwarp nombre` · `/warp nombre` | Puntos de teletransporte públicos |
| `/time set day` · `/weather clear` | Hora y clima |
| `/gamerule keepInventory true` | Reglas del juego (ej. no perder inventario al morir) |
| `/difficulty normal` | Dificultad (temporal; la permanente está en `.env`) |
| `/worldborder set 6000` | Borde del mundo (diámetro en bloques) |
| `/co rollback ... r:#global` | Rollback en todo el mundo |
| `/essentials reload` | Recargar EssentialsX tras cambiar su configuración |
| `/spark profiler start` · `/spark profiler stop` | Perfilado de lag (§13.3) |
| `/stop` | Apaga el servidor; Docker lo arranca de nuevo solo (reinicio). Avisa antes |

### 6.2 Reglas del servidor
Las reglas que muestra `/rules` están en el archivo `data/plugins/Essentials/rules.txt` de la VM. Pide a un administrador de sistema que lo edite (§9.10) o, si eres tú, `nano data/plugins/Essentials/rules.txt` y luego `/essentials reload`.

### 6.3 Dar permisos de warp a todos
Por defecto los jugadores no pueden usar `/warp`. Para permitirlo, el dueño ejecuta `/lp group default permission set essentials.warp true` y `/lp group default permission set essentials.warps.* true`.

### 6.4 ⚠ No banear por IP
`/banip` bloquea una dirección IP. Como **todos los alumnos que juegan desde la red de la universidad comparten la misma IP pública** (NAT, §1.2), un ban por IP expulsaría a toda la clase. Banea siempre por **nick** (`/ban Nick`).

---

## 7. Guía del dueño del servidor

El dueño es el jugador indicado en `SERVER_OWNER` (`.env`). Tiene prefijo `[Dueño]`, todos los permisos, incluido LuckPerms, y es el único OP.

### 7.1 Nombrar y quitar roles (dentro del juego)

| Acción | Comando |
|---|---|
| Hacer moderador | `/lp user Nick parent set moderador` |
| Hacer admin | `/lp user Nick parent set admin` |
| Quitar rol (volver a jugador) | `/lp user Nick parent set default` |
| Ver el rol y permisos de alguien | `/lp user Nick info` |
| Ver los grupos | `/lp listgroups` |
| Ver permisos de un grupo | `/lp group moderador permission info` |

También desde la VM con `./scripts/roles.sh` (§9.6). El jugador debe haber entrado alguna vez o tener cuenta oficial (LuckPerms busca su identificador en Microsoft).

### 7.2 Cambiar permisos de un grupo

| Acción | Comando |
|---|---|
| Dar un permiso | `/lp group moderador permission set essentials.fly true` |
| Denegar un permiso | `/lp group admin permission set essentials.give false` |
| Quitar un permiso (volver a lo heredado) | `/lp group moderador permission unset essentials.fly` |
| Editor web visual | `/lp editor` → abre el enlace, edita y pulsa **Save**; copia el comando que te da y pégalo en el chat |

> Los cambios hechos así quedan guardados, pero `./scripts/roles.sh setup` vuelve a fijar los permisos definidos en el script (no borra los extra). Para cambios permanentes y documentados, edita `scripts/roles.sh` (§9.10).

### 7.3 Responsabilidades del dueño
- Elegir moderadores y admins de confianza y revisar la lista cada mes (§10).
- Definir las reglas (§6.2) y el protocolo de sanciones (§5.2).
- Decidir quién es administrador de sistema (§9.7): es el nivel de acceso más alto.

---

## 8. Administrador de sistema: instalación desde cero

Tiempo estimado: 1–2 horas (más la pregeneración, que corre sola). Necesitas: una computadora con internet, una tarjeta (solo para verificar la cuenta de Oracle; no se cobra) y tu cuenta de Minecraft.

> **¿Oracle rechaza tu tarjeta o no tienes una?** Puedes instalar el servidor en una **Raspberry Pi** en tu casa, gratis y sin tarjeta: sigue [docs/08-raspberry-pi.md](08-raspberry-pi.md) en lugar de §8.2–§8.5. El resto del manual aplica igual.

### 8.1 Crear tu par de llaves SSH (en TU computadora)

**Windows 10/11:** abre **PowerShell** (tecla Windows → escribe "PowerShell" → Enter).
**Mac:** abre **Terminal** (Cmd+Espacio → "Terminal"). **Linux:** abre una terminal.

```bash
ssh-keygen -t ed25519 -C "minecraft30"
```

- Cuando pregunte dónde guardarla, pulsa **Enter** (ubicación por defecto).
- Cuando pida *passphrase*, escribe una contraseña para proteger la llave (recomendado) y repítela. No se ve al escribir; es normal.

Se crean dos archivos en la carpeta `.ssh` de tu usuario:
- `id_ed25519` → **llave privada. No la compartas nunca. Haz una copia de seguridad** (USB, gestor de contraseñas): si la pierdes y nadie más tiene acceso, no podrás entrar a la VM.
- `id_ed25519.pub` → llave pública. Esta sí se comparte.

Mostrar la llave pública para copiarla:
- **Windows:** `type $env:USERPROFILE\.ssh\id_ed25519.pub`
- **Mac/Linux:** `cat ~/.ssh/id_ed25519.pub`

Es una sola línea que empieza por `ssh-ed25519 AAAA...`.

### 8.2 Crear la cuenta de Oracle Cloud
1. Ve a <https://www.oracle.com/cloud/free/> → **Start for free**.
2. Rellena tus datos y verifica el correo.
3. **Home Region:** elige la más cercana a los jugadores (menos ping). **No se puede cambiar después.**
4. Añade la tarjeta (Oracle hace un cargo de verificación que devuelve).
5. **Recomendado:** en la consola → **Billing & Cost Management → Upgrade and Manage Payment** → **Upgrade to Pay As You Go**. Sigue costando **0 $** si solo usas recursos *Always Free*, pero evita que Oracle recupere la VM por inactividad y facilita conseguir capacidad ARM.
6. Pon una alerta: **Billing → Budgets → Create Budget** con 1 $ y tu correo. Si algo empezara a costar, te avisa.

> **Límites gratuitos:** la documentación oficial indica 4 OCPU + 24 GB para ARM, pero en 2026 se ha reportado una reducción a ~2 OCPU + 12 GB. Mira tus límites reales en **Governance & Administration → Limits, Quotas and Usage** (busca "A1"). El proyecto funciona con ambos.

### 8.3 Crear la máquina virtual
Consola de Oracle → menú ☰ → **Compute → Instances → Create instance**:

1. **Name:** `minecraft30`.
2. **Image and shape → Edit:**
   - **Change image** → **Ubuntu** → **Canonical Ubuntu 24.04** (no la "Minimal") → Select.
   - **Change shape** → **Ampere** → **VM.Standard.A1.Flex** → OCPUs y memoria: el máximo gratuito que tengas (2/12 o 4/24) → Select.
3. **Networking:** **Create new virtual cloud network** y **Create new public subnet**; **Assign a public IPv4 address: Yes**.
4. **Add SSH keys:** **Paste public keys** → pega tu llave pública (§8.1).
5. **Boot volume:** marca **Specify a custom boot volume size** → `100` GB.
6. **Create**. En 1–2 minutos estará en verde (**Running**).
7. Copia la **Public IP address** de la página de la instancia. Es tu `IP_PUBLICA`.

> Si aparece **"Out of capacity"**: cambia de *Availability Domain* (AD-1, AD-2, AD-3) en el paso de *Placement*, o inténtalo en otro momento. Con *Pay As You Go* ocurre mucho menos.

### 8.4 Hacer la IP fija (recomendado)
La IP efímera solo cambia si se borra la VM, pero reservarla es gratis (1 por cuenta) y evita sorpresas:
Instancia → **Attached VNICs** → la VNIC → **IPv4 Addresses** → ⋮ en la IP → **Edit** → **Reserved public IP** → **Create new** → Update.

### 8.5 Abrir el puerto de Minecraft en Oracle (para cualquier IP)
Instancia → enlace de la **Subnet** → **Security Lists** → **Default Security List** → **Add Ingress Rules**:

| Campo | Valor |
|---|---|
| Source Type | CIDR |
| Source CIDR | `0.0.0.0/0` (cualquier IP: casas, universidad, móviles) |
| IP Protocol | TCP |
| Source Port Range | (vacío) |
| Destination Port Range | `25565` |
| Description | Minecraft |

**Añade también estas tres reglas para Minecraft Bedrock** (pulsa **+ Another Ingress Rule** para cada una), todas con Source CIDR `0.0.0.0/0`:

| IP Protocol | Destination Port Range | Description |
|---|---|---|
| UDP | `19132` | Bedrock (RakNet) |
| TCP | `19132` | Bedrock (señalización NetherNet) |
| UDP | `19133` | Bedrock (NetherNet) |

**Add Ingress Rules**. El puerto 22 (SSH) ya viene abierto a `0.0.0.0/0`, lo que permite a los administradores de sistema entrar desde cualquier lugar (protegido por llaves y fail2ban). **No abras el 25575 (RCON).**

### 8.6 Conectarte a la VM
Desde tu computadora (PowerShell/Terminal):

```bash
ssh ubuntu@IP_PUBLICA
```

- La primera vez preguntará *"Are you sure you want to continue connecting?"* → escribe `yes`.
- Si pusiste passphrase, te la pide.
- Verás algo como `ubuntu@minecraft30:~$`. Ya estás **dentro de la VM**: todo lo que escribas se ejecuta allí. Para salir: `exit`.

Consejos de terminal: **Tab** autocompleta nombres; **↑** repite comandos anteriores; **Ctrl+C** cancela el comando en curso; pegar: clic derecho (Windows) o `Ctrl+Shift+V` (Linux) o `Cmd+V` (Mac).

### 8.7 Descargar el proyecto
```bash
sudo git clone https://github.com/usx22/minecraft30.git /opt/minecraft30 && sudo chown -R "$USER": /opt/minecraft30
```

Si el repositorio es **privado**, git pedirá usuario y contraseña. La contraseña **no** es la de GitHub sino un *token*: en GitHub → foto de perfil → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token** → *Repository access*: solo `minecraft30` → *Permissions → Contents: Read-only* → **Generate** → copia el token y pégalo como contraseña.

Entra en la carpeta (todos los comandos siguientes se ejecutan desde aquí):

```bash
cd /opt/minecraft30
```

### 8.8 Preparar y asegurar la VM
```bash
sudo ./scripts/bootstrap-host.sh
```

Tarda 5–10 minutos. Hace, en orden: actualizar Ubuntu y activar actualizaciones automáticas de seguridad; instalar Docker; desactivar el acceso SSH con contraseña; abrir 25565 en el firewall de la VM; activar fail2ban; crear 4 GB de swap; instalar los servicios systemd y el grupo `mcadmin`.

Al terminar, **sal y vuelve a entrar** (para que se apliquen los grupos `docker` y `mcadmin`):

```bash
exit
```

```bash
ssh ubuntu@IP_PUBLICA
```

```bash
cd /opt/minecraft30
```

### 8.9 Crear la configuración (`.env`)
```bash
./scripts/install.sh
```

La primera vez solo crea `.env` (con una contraseña RCON aleatoria) y se detiene. Ábrelo:

```bash
nano .env
```

Cambia como mínimo (explicación de cada variable en §14.1):
- `SERVER_OWNER=` tu nick exacto de Minecraft.
- `WHITELIST=` tu nick y los de los primeros jugadores, separados por comas, sin espacios.
- `TZ=` tu zona horaria (ej. `America/Bogota`, `America/Lima`, `America/Santiago`, `America/Argentina/Buenos_Aires`, `Europe/Madrid`).
- `MC_MEMORY` y `CONTAINER_MEM_LIMIT`: `8G`/`10g` si la VM tiene 12 GB; `12G`/`14g` si tiene 24 GB.
- `MC_VERSION_AUTO=true` (déjalo así): el servidor usa sola la versión de Minecraft más nueva que soportan **todos** los plugins (§9.9).

Guarda con `Ctrl+O`, `Enter`, y sal con `Ctrl+X`.

### 8.10 Instalar y arrancar
```bash
./scripts/install.sh
```

Qué verás:
1. *Descargando imágenes...* (1–3 min).
2. *Arrancando...*: descarga Paper y los plugins y genera el mundo (3–10 min la primera vez).
3. *Reiniciando una vez para aplicar parches...* (activa el anti-xray).
4. *Creando roles (LuckPerms)...*
5. **¡Servidor listo!**

Si algo falla, el script lo dice y sugiere `docker compose logs mc` (§13).

### 8.11 Primera prueba
1. En Minecraft (§4.2) conéctate a `IP_PUBLICA`.
2. Deberías ver `[Dueño]` delante de tu nombre en el chat.
3. Prueba `/lp user TuNick info`: debe mostrar el grupo `owner`.
4. Pide a alguien **desde otra red** (su casa, datos móviles) que entre, tras añadirlo a la whitelist (§9.6). Así verificas el acceso desde cualquier IP.

### 8.12 Verificación del sistema
```bash
./scripts/status.sh
```

```bash
systemctl list-timers minecraft-update.timer
```

```bash
sudo ss -tlnp
```

En la última, el puerto **25565** debe aparecer y el **25575 no** debe aparecer con `0.0.0.0` (RCON solo es interno).

Prueba de reinicio (el servidor debe volver solo en ~3 minutos):

```bash
sudo reboot
```

### 8.13 Tamaño del mundo y pregeneración

Un mundo de Minecraft es prácticamente infinito (30 millones de bloques hacia cada lado), pero cada zona nueva que alguien explora hay que **generarla** (mucha CPU) y **guardarla** (disco y backups). Por eso se elige un tamaño, se **pregenera** antes de abrir el servidor y se pone un **borde de mundo**. 1 bloque = 1 metro.

Datos **medidos** en la prueba del proyecto (2 núcleos, como la VM gratuita de 2 OCPU): 2×2 km = 16.129 chunks, **16 min 45 s** (~16 chunks/s), **168 MB** en disco y **110 MB** por backup comprimido. A partir de ahí (crece con el área):

| Radio (`chunky radius`) | Lado del mundo | Superficie | Pregeneración (2 OCPU) | Disco | Backups (28 = 7 días × 4/día) | Recomendado para |
|---|---|---|---|---|---|---|
| 1000 | 2 × 2 km | 4 km² | ~17 min | ~170 MB | ~3 GB | Pruebas |
| 2000 | 4 × 4 km | 16 km² | ~1 h 10 min | ~0,7 GB | ~12 GB | Hasta ~20 jugadores |
| **3000 (por defecto)** | **6 × 6 km** | **36 km²** | **~2 h 30 min** | **~1,5 GB** | **~28 GB** | **30–60 jugadores** |
| 4000 | 8 × 8 km | 64 km² | ~4 h 30 min | ~2,7 GB | ~50 GB | 60–100 jugadores |
| 5000 | 10 × 10 km | 100 km² | ~7 h | ~4,2 GB | ~77 GB ⚠ | Ver nota |

Con el tamaño por defecto, cada uno de 30 jugadores tiene en promedio más de 1 km² (~1000 × 1000 bloques): sobra espacio. El Nether ocupa 8 veces menos distancia (1 bloque del Nether = 8 del mundo normal), así que basta con un radio de ~1000. Los tamaños **crecen** a medida que los jugadores construyen.

> ⚠ El disco gratuito total de Oracle es de 200 GB. Con mundos de 8 km o más, amplía el boot volume a ~150–200 GB o baja `PRUNE_BACKUPS_DAYS` (por ejemplo a 3) para que los backups quepan.

Hazlo antes de abrir el servidor a todos. Para el tamaño por defecto (radio de 3000 bloques ≈ 6 km de lado):

```bash
./scripts/console.sh "chunky radius 3000"
```

```bash
./scripts/console.sh "chunky start"
```

Progreso (tarda varias horas con 2 OCPU; se puede jugar mientras, con algo de lag):

```bash
./scripts/console.sh "chunky progress"
```

Cuando termine, fija el borde para que no se genere más terreno:

```bash
./scripts/console.sh "worldborder set 6000"
```

Cuando termine el mundo normal, pregenera el Nether (radio 1000) y vuelve a seleccionar el mundo normal:

```bash
./scripts/console.sh "chunky world minecraft:the_nether"
```

```bash
./scripts/console.sh "chunky radius 1000"
```

```bash
./scripts/console.sh "chunky start"
```

Al terminar: `./scripts/console.sh "chunky world minecraft:overworld"`. El borde del Nether se fija desde dentro del Nether con `/worldborder set 2000` (como admin).

### 8.14 Nombre de dominio gratuito (opcional)
1. Entra en <https://www.duckdns.org> e inicia sesión (GitHub, Google...).
2. Escribe un subdominio (ej. `redes-mc`) → **add domain**.
3. En **current ip** pon tu `IP_PUBLICA` → **update ip**.
4. Los jugadores ya pueden usar `redes-mc.duckdns.org` como dirección.

### 8.15 Copia de backups fuera de la VM
Configúrala ahora (§9.8): si se pierde la VM, se pierde todo lo que solo esté en ella.

### 8.16 Lista final de instalación
- [ ] Entré al servidor desde Minecraft y tengo `[Dueño]`.
- [ ] Alguien entró desde **otra red**.
- [ ] `status.sh` muestra `healthy` y TPS ≈ 20.
- [ ] Tras `sudo reboot` el servidor volvió solo.
- [ ] El timer de actualización aparece en `systemctl list-timers`.
- [ ] El 25575 no está expuesto.
- [ ] Mundo pregenerado y borde fijado.
- [ ] Llave privada SSH respaldada y (recomendado) un segundo administrador de sistema añadido (§9.7).
- [ ] Copia de backups fuera de la VM configurada (§9.8).
- [ ] Alerta de presupuesto de 1 $ en Oracle.

---

## 9. Administrador de sistema: operación y procedimientos

Todos los comandos se ejecutan **dentro de la VM** y **desde la carpeta del proyecto**. Al entrar por SSH, lo primero siempre es:

```bash
cd /opt/minecraft30
```

### 9.1 Estado y logs

| Tarea | Comando |
|---|---|
| Estado completo (contenedores, salud, jugadores, TPS, RAM, disco, backups) | `./scripts/status.sh` |
| Logs del servidor en vivo (salir: `Ctrl+C`) | `docker compose logs -f --tail 100 mc` |
| Logs de los backups | `docker compose logs --tail 50 backup` |
| Log del juego de hoy | `less data/logs/latest.log` (salir: `q`) |
| Quién entró y desde qué IP | `grep "logged in" data/logs/latest.log` |
| Logs de la última actualización automática | `journalctl -u minecraft-update -n 80` |
| Memoria y swap de la VM | `free -h` |
| Espacio en disco | `df -h /` |
| IPs bloqueadas por fail2ban | `sudo fail2ban-client status sshd` |

### 9.2 Arrancar, parar, reiniciar

| Acción | Comando | Nota |
|---|---|---|
| Reiniciar el servidor de Minecraft | `docker compose restart mc` | Avisa 30 s en el chat y guarda el mundo |
| Parar todo | `docker compose stop` | Se queda parado hasta `start` (y no arranca al reiniciar la VM hasta que lo inicies) |
| Arrancar | `docker compose start` | |
| Aplicar cambios de `.env` o `docker-compose.yml` | `docker compose up -d` | Recrea solo los contenedores que cambiaron |
| Borrar contenedores (no el mundo) | `docker compose down` | `data/` y `backups/` se conservan |

Mensaje previo a un reinicio manual: `./scripts/console.sh "say Reinicio en 5 minutos"`.

### 9.3 Consola del servidor
- Interactiva: `./scripts/console.sh` → escribe comandos **sin** `/` (ej. `list`, `say hola`). Salir: `Ctrl+C`.
- Un solo comando: `./scripts/console.sh "lp user Nick info"`.

La consola tiene **todos** los permisos (como el dueño).

### 9.4 Whitelist

```bash
./scripts/whitelist.sh agregar Nick1 Nick2 Nick3
```

```bash
./scripts/whitelist.sh quitar Nick
```

```bash
./scripts/whitelist.sh lista
```

Para dar acceso a toda la clase de una vez, pasa todos los nicks separados por espacios. Los nicks se validan (3–16 caracteres: letras, números y `_`).

**Jugadores de Bedrock** (por gamertag, entre comillas si tiene espacios). El jugador debe haber **intentado entrar una vez** antes (si no, Floodgate responde *"Unable to find user in our cache"*):

```bash
./scripts/whitelist.sh bedrock "Gamertag Del Jugador"
```

```bash
./scripts/whitelist.sh quitar-bedrock "Gamertag Del Jugador"
```

### 9.5 Cambiar la configuración del juego
1. `nano .env` y cambia la variable (ej. `MAX_PLAYERS=60`, `VIEW_DISTANCE=10`, `DIFFICULTY=hard`, `MOTD=...`).
2. Guarda y aplica: `docker compose up -d` (reinicia el servidor ~1–2 min).

Todas las variables: §14.1.

### 9.6 Roles desde la VM

| Acción | Comando |
|---|---|
| Moderador | `./scripts/roles.sh mod Nick` |
| Admin | `./scripts/roles.sh admin Nick` |
| Quitar rol | `./scripts/roles.sh quitar Nick` |
| Ver | `./scripts/roles.sh info Nick` |
| Recrear grupos y permisos (tras editar el script) | `./scripts/roles.sh setup` |

Para jugadores de **Bedrock** usa su nombre dentro del servidor, con el punto: `./scripts/roles.sh mod .Cool_Guy` (debe haber entrado al menos una vez). En el chat del juego, igual: `/mute .Cool_Guy 10m`.

### 9.7 Añadir y quitar administradores de sistema
Un administrador de sistema adicional garantiza que, si pierdes tu llave, alguien más puede entrar.

1. **La persona nueva** crea su llave en su computadora (§8.1) y te envía **solo** el contenido de su `id_ed25519.pub` (nunca la privada).
2. **Tú** (con sudo) ejecutas, con un nombre de usuario en minúsculas:

```bash
sudo ./scripts/sysadmins.sh agregar ana "ssh-ed25519 AAAA...resto-de-la-llave... ana@pc"
```

3. La persona entra con `ssh ana@IP_PUBLICA` y trabaja en `/opt/minecraft30`.

| Acción | Comando |
|---|---|
| Ver administradores | `sudo ./scripts/sysadmins.sh lista` |
| Quitar acceso (cierra sus sesiones y borra su usuario) | `sudo ./scripts/sysadmins.sh quitar ana` |
| Darle también `sudo` (administrar Ubuntu) | `sudo usermod -aG sudo ana` |

> Pertenecer al grupo `docker` equivale en la práctica a ser root. Solo para personas de máxima confianza. Si alguien deja el equipo, quítale el acceso **y** cambia la contraseña RCON (§9.11).

### 9.8 Backups
- **Automáticos:** cada 6 h en `backups/`, se borran a los 7 días. Configurable con `BACKUP_INTERVAL` y `PRUNE_BACKUPS_DAYS`.
- **Manual (antes de cualquier cambio arriesgado):** `./scripts/backup-now.sh`
- **Listar:** `./scripts/restore.sh`
- **Restaurar:** `./scripts/restore.sh backups/world-AAAAMMDD-HHMMSS.tar.zst` → escribe `si`. El mundo actual se mueve a `data.antes-de-restaurar-<fecha>` (bórralo con `sudo rm -rf data.antes-de-restaurar-*` cuando estés seguro). Si el backup está dañado, el script lo detecta y **vuelve a poner el mundo anterior** automáticamente.

**Copia fuera de la VM** (elige una):

a) **A tu computadora** (ejecutar en TU computadora, no en la VM; `scp` viene incluido en Windows 10/11, Mac y Linux):

```bash
scp -r ubuntu@IP_PUBLICA:/opt/minecraft30/backups ./backups-minecraft
```

b) **Automática a la nube con rclone** (en la VM). Google Drive da 15 GB gratis; Oracle Object Storage 20 GB *Always Free*:

```bash
sudo apt install -y rclone
```

```bash
rclone config
```

En el asistente: `n` (nuevo) → nombre `nube` → elige el tipo (ej. `drive`) → deja lo demás por defecto → para autorizar sin navegador en la VM, rclone te indica un comando `rclone authorize` que ejecutas en tu computadora y pegas el resultado. Luego programa la copia:

```bash
crontab -e
```

Añade al final (copia cada 12 h los backups de las últimas 13 h):

```
30 */12 * * * rclone copy /opt/minecraft30/backups nube:minecraft-backups --max-age 13h
```

### 9.9 Actualizaciones
- **Automáticas:** cada lunes 05:00 (`update.sh`): aviso → backup → `git pull` → nuevas imágenes → reinicio → comprobación.
- **Manual con aviso de 5 min:** `./scripts/update.sh`
- **Manual inmediata (servidor vacío):** `./scripts/update.sh --ahora`
- **Ver próxima ejecución:** `systemctl list-timers minecraft-update.timer`
- **Desactivar las automáticas:** `sudo systemctl disable --now minecraft-update.timer` (reactivar: `sudo systemctl enable --now minecraft-update.timer`).
- **Cambiar el horario:** `sudo systemctl edit --full minecraft-update.timer`, cambia `OnCalendar=` (ej. `Sun *-*-* 04:00:00`) y guarda.

**Versión de Minecraft.** Con `MC_VERSION_AUTO=true` (por defecto) el servidor elige en cada arranque la versión **más nueva que soportan todos los plugins**. Así nunca deja de arrancar porque un plugin aún no se actualizó, y la actualización semanal avanza de versión sola cuando todos están listos. En el log aparece `Resolved Minecraft version X from Modrinth projects`.

Para **fijar** una versión concreta:
1. `./scripts/backup-now.sh`
2. `nano .env` → `MC_VERSION_AUTO=false` y `MC_VERSION=26.1.2` (la versión deseada).
3. `./scripts/update.sh --ahora`
4. Comprueba en los logs que todos los plugins cargaron: `docker compose logs mc | grep -iE "error|could not"`.

> **No bajes** la versión de un mundo ya abierto con otra más nueva: puede corromperse. Para volver atrás, restaura un backup previo.

### 9.10 Cambios permanentes en archivos del proyecto
Hay dos formas:

**A) En el repositorio (recomendado: queda en el historial y se aplica en todas las instalaciones).** Edita el archivo en GitHub (botón ✏️) o en tu computadora, haz *commit* y *push*. En la VM se aplicará en la próxima actualización automática, o al momento:

```bash
git pull && docker compose up -d
```

**B) Solo en esta VM**, sin tocar archivos versionados, con `docker-compose.override.yml` (está en `.gitignore`, así `git pull` nunca choca). Ejemplo, añadir un plugin (hay que repetir la lista completa):

```yaml
services:
  mc:
    environment:
      MODRINTH_PROJECTS: |-
        luckperms
        essentialsx
        coreprotect
        chunky
        lpc-chat
        viaversion
        viabackwards
        nombre-del-plugin-en-modrinth
```

Luego `docker compose up -d`. Si usas el modo vanilla (`COMPOSE_FILE` en `.env`), añade `:docker-compose.override.yml` al final de `COMPOSE_FILE`, porque en ese caso Compose no lo carga automáticamente.

**Archivos de configuración de plugins** (EssentialsX, CoreProtect...) están en `data/plugins/<Plugin>/`. Edítalos con sudo, porque pertenecen al usuario del contenedor: `sudo nano data/plugins/Essentials/config.yml`, y recarga (`/essentials reload`) o reinicia.

### 9.11 Cambiar la contraseña RCON
Hazlo si sospechas que se filtró `.env` o si un administrador de sistema deja el equipo.

```bash
sed -i "s|^RCON_PASSWORD=.*|RCON_PASSWORD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)|" .env
```

```bash
docker compose up -d --force-recreate
```

### 9.12 Mover el servidor a otra máquina
1. En la VM vieja: `./scripts/backup-now.sh` y copia a tu computadora el último backup y el archivo `.env` (§9.8a; `.env` con `scp ubuntu@IP:/opt/minecraft30/.env .`).
2. Nueva VM: §8.3–§8.8.
3. Copia `.env` a `/opt/minecraft30/` y el backup a `/opt/minecraft30/backups/` (con `scp` en sentido contrario).
4. `./scripts/restore.sh backups/ARCHIVO` → `si`.
5. `./scripts/roles.sh setup` y comprueba con `./scripts/status.sh`.
6. Si la IP cambió, actualízala en DuckDNS y avisa a los jugadores.

### 9.13 Puerto alternativo para redes que bloquean el 25565
Algunas redes (empresas, colegios) solo dejan salir conexiones a puertos web. Puedes **además** aceptar jugadores en el puerto 443:

1. Crea `docker-compose.override.yml` (o añade a él):

```yaml
services:
  mc:
    ports:
      - "443:25565/tcp"
```

2. Abre 443/TCP desde `0.0.0.0/0` en la Security List de Oracle (§8.5, igual que 25565).
3. Abre 443 en el firewall de la VM. En la imagen de Oracle:

```bash
sudo sed -i '0,/^-A INPUT .*REJECT/s||-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT\n&|' /etc/iptables/rules.v4 && sudo iptables-restore < /etc/iptables/rules.v4 && sudo systemctl restart docker
```

   (Se edita el archivo de reglas de Oracle, se recarga y se reinicia Docker para que vuelva a crear sus propias reglas.)

   En otras VMs con UFW: `sudo ufw allow 443/tcp`.
4. `docker compose up -d`.
5. Los jugadores en esas redes usan `IP_PUBLICA:443`. El resto sigue con la dirección normal. El límite anti-flood también se aplica a este puerto.

### 9.14 Reiniciar o apagar la VM
- Reinicio: `sudo reboot` (el servidor vuelve solo).
- Apagado: desde la consola de Oracle (**Stop**). Ojo: una VM parada mucho tiempo con cuenta solo *Free* puede ser recuperada por Oracle.

---

## 10. Mantenimiento programado

**Diario (2 minutos, cualquier administrador de sistema o admin):**
- [ ] `./scripts/status.sh`: `healthy`, TPS ≥ 19, hay backup de las últimas 6 h.
- [ ] Revisar `/helpop` y reportes pendientes (moderadores).

**Semanal (lunes, después de la actualización):**
- [ ] `journalctl -u minecraft-update -n 80`: la actualización terminó con *"Actualización completada"*.
- [ ] `df -h /`: uso de disco < 80 %.
- [ ] `docker compose logs mc | grep -iE "error|exception" | tail`: errores nuevos de plugins.

**Mensual:**
- [ ] **Probar una restauración** en el servidor de prueba (un backup que no se ha probado no es un backup). Ejemplo: extraer el último backup en una carpeta temporal y comprobar que contiene `world/level.dat`:
  `docker run --rm -v "$PWD/backups:/b:ro" --entrypoint tar itzg/mc-backup:latest -tf "/b/$(ls -t backups | head -1)" | grep -m1 "world/level.dat"` (debe mostrar `./world/level.dat`).
- [ ] Copia fuera de la VM al día (§9.8).
- [ ] Revisar la lista de administradores de sistema (`sudo ./scripts/sysadmins.sh lista`) y de moderadores/admins (`/lp group admin listmembers`, `/lp group moderador listmembers`). Quitar a quien ya no participe.
- [ ] Revisar en Oracle **Billing → Cost Analysis** que el costo sea 0 $.
- [ ] `sudo apt list --upgradable` vacío o casi (las automáticas funcionan).

---

## 11. Respuesta a incidentes

### 11.1 Griefing o robo
1. Moderador: investigar y revertir con CoreProtect (§5.4).
2. Sancionar (§5.2).
3. Si es masivo (muchas zonas/jugadores): admin usa `r:#global`. Último recurso: restaurar backup (§9.8), sabiendo que todos pierden el progreso desde ese backup.

### 11.2 Un moderador o admin abusa o su cuenta fue robada
1. El dueño (o la consola) le quita el rol **de inmediato**: `./scripts/roles.sh quitar Nick` y `./scripts/console.sh "kick Nick"`.
2. Revisa y revierte lo que hizo: `/co lookup u:Nick t:1d`, `/co rollback u:Nick t:1d r:#global`.
3. Si fue robo de cuenta, el jugador debe cambiar su contraseña de Microsoft antes de recuperar el rol.

### 11.3 El servidor no responde
1. `./scripts/status.sh`. Si `mc` está `restarting` o `unhealthy`: `docker compose logs --tail 200 mc` y busca el error (§13).
2. Si la VM no responde a SSH: consola de Oracle → instancia → **Reboot**. Mira también el estado de Oracle en <https://ocistatus.oraclecloud.com>.

### 11.4 Lag fuerte
Ver §13.3.

### 11.5 Disco lleno
1. `df -h /` y `du -sh /opt/minecraft30/* | sort -h`.
2. Liberar: borrar backups viejos (`ls -lt backups`, `sudo rm backups/ARCHIVO`), restos de restauraciones (`sudo rm -rf data.antes-de-restaurar-*`), imágenes viejas (`docker image prune -af`), logs antiguos (`sudo rm data/logs/*.log.gz`).
3. Bajar `PRUNE_BACKUPS_DAYS` en `.env` y `docker compose up -d`.

### 11.6 Oracle borró o detuvo la VM
1. Si solo está parada: **Start** desde la consola.
2. Si fue eliminada: crea otra VM (§8.3–§8.10) y restaura desde la copia **fuera de la VM** (§9.12). Activa *Pay As You Go* para evitar que se repita.

### 11.7 Se filtró la contraseña RCON o el archivo `.env`
Cambia la contraseña (§9.11). Como RCON no está expuesto a internet, el riesgo es bajo, pero cámbiala igualmente.

### 11.8 Perdí mi llave SSH
- Si hay otro administrador de sistema: que ejecute `sudo ./scripts/sysadmins.sh agregar tu-usuario "tu-nueva-llave.pub"` (o añada tu nueva llave a `/home/ubuntu/.ssh/authorized_keys` si tiene sudo).
- Si no hay nadie más: en la consola de Oracle, instancia → **Console connection** permite acceso de emergencia (requiere configurar una contraseña de usuario previamente). Si no es posible, crea una VM nueva y restaura desde la copia externa (§9.12). **Por eso es importante tener dos administradores de sistema y respaldar la llave.**

### 11.9 Un ataque de conexiones (bots, flood)
1. `sudo iptables -L MC-PROTECT -n -v`: los contadores de `DROP` muestran cuánto se está bloqueando.
2. La whitelist impide que los bots entren al juego, aunque consuman conexiones.
3. Si persiste y afecta al juego, considera un proxy con protección DDoS (ver [07-alternativas-y-costos.md](07-alternativas-y-costos.md)).

---

## 12. Modo vanilla: servidor oficial de Mojang

Por defecto el servidor es **Paper**, que ejecuta el juego oficial optimizado y es 100 % compatible con el **cliente oficial** de Minecraft Java. Si por algún motivo (por ejemplo, un requisito del curso) necesitas el **servidor oficial sin modificar** de Mojang, el proyecto lo soporta.

### 12.1 Diferencias

| | Paper (por defecto) | Vanilla (oficial) |
|---|---|---|
| Cliente que usan los jugadores | Minecraft Java **oficial** | Minecraft Java **oficial** |
| Jugadores estimados (2 OCPU) | ~50–70 | ~20–30 |
| Roles moderador/admin separados | Sí (LuckPerms) | **No**: solo OP |
| Comandos de moderación (mute, tempban, jail) | Sí (EssentialsX) | Solo `kick`, `ban`, `pardon` |
| Revertir griefing (CoreProtect) | Sí | **No** (solo restaurar backup) |
| Anti-xray | Sí | No |
| Entrar con otras versiones del cliente | Sí (ViaVersion) | No, versión exacta |
| Jugadores de Bedrock (móvil, Windows) | Sí (Geyser + Floodgate) | No |
| Backups, actualizaciones, firewall, whitelist, online-mode | Sí | Sí |

### 12.2 Activarlo
1. Backup: `./scripts/backup-now.sh`
2. `nano .env` y quita el `#` de la línea:

```
COMPOSE_FILE=docker-compose.yml:docker-compose.vanilla.yml
```

3. `docker compose up -d`

### 12.3 Roles en vanilla
- `./scripts/roles.sh admin Nick` → lo hace **OP de nivel 3**: puede `kick`, `ban`, `whitelist`, `gamemode`, `tp`, `give`... pero no `/stop` ni `/save-off`.
- `./scripts/roles.sh quitar Nick` → `deop`.
- No existe "moderador": en vanilla todo OP del mismo nivel tiene los mismos poderes (incluido dar OP a otros con nivel 3). Elige OPs con mucho cuidado.

### 12.4 Volver a Paper
Vuelve a poner el `#` delante de `COMPOSE_FILE` y `docker compose up -d`. Paper convierte automáticamente el mundo vanilla. Luego `./scripts/roles.sh setup`.

> **Cuidado al pasar de Paper a vanilla con un mundo existente:** Paper guarda el Nether y el End en carpetas separadas (`world_nether`, `world_the_end`) y vanilla dentro de `world`. Si cambias a vanilla, el Nether y el End aparecerán vacíos (regenerados) a menos que muevas las carpetas manualmente. Decide el modo **antes** de empezar a jugar.

---

## 13. Solución de problemas

### 13.1 Instalación y arranque

| Síntoma | Causa probable | Solución |
|---|---|---|
| `ssh: connect to host ... Connection timed out` | IP equivocada, VM parada, o puerto 22 cerrado en la Security List | Comprueba la IP y que la VM está **Running** |
| `Permission denied (publickey)` | Llave incorrecta o usuario equivocado | Usuario `ubuntu` en Ubuntu de Oracle. Si tu llave no está en la ruta por defecto: `ssh -i ruta/llave ubuntu@IP` |
| `permission denied while trying to connect to the Docker daemon` | No has vuelto a entrar tras `bootstrap-host.sh` | `exit` y vuelve a entrar por SSH |
| `Define RCON_PASSWORD en .env` | Falta `.env` | `./scripts/install.sh` |
| `Pon tu nick real en SERVER_OWNER` | No editaste `.env` | §8.9 |
| `El nick 'X' no existe como cuenta oficial` / log `Could not resolve user from Playerdb` | Nick mal escrito en `SERVER_OWNER` o `WHITELIST` (un nick inexistente impide arrancar) | Corrige el nick en `.env` (mayúsculas incluidas) |
| `mc` en bucle de reinicios, log con `OutOfMemoryError` o `exit code 137` | Poca RAM | Baja `MC_MEMORY` y `CONTAINER_MEM_LIMIT` (deja ≥ 2 GB de diferencia) |
| Log: `AccessDeniedException` / `permission denied` en `/data` | Dueño de `data/` incorrecto | `sudo chown -R 1000:1000 data backups` |
| Log: `No files are available for the project ...` | Fijaste `MC_VERSION` (con `MC_VERSION_AUTO=false`) a una versión que algún plugin aún no soporta | Vuelve a `MC_VERSION_AUTO=true` o fija `MC_VERSION` a la versión anterior (§9.9) o espera unos días |
| `git pull` dice *dubious ownership* | Repositorio de otro usuario | `sudo git config --system --add safe.directory /opt/minecraft30` |
| `git pull` falla por cambios locales | Editaste archivos versionados en la VM | `git stash` (guarda tus cambios aparte) y `git pull`; mejor usa el override (§9.10) |

### 13.2 Conexión de jugadores

| Síntoma | Solución |
|---|---|
| Nadie puede entrar (*timed out*) | 1) `./scripts/status.sh` → ¿`healthy`? 2) ¿Regla 25565 en la Security List con `0.0.0.0/0`? (§8.5) 3) En la VM: `sudo iptables -L INPUT -n --line-numbers` debe tener `ACCEPT tcp dpt:25565` **antes** del `REJECT`. Si no: vuelve a ejecutar `sudo ./scripts/bootstrap-host.sh`. |
| Entra la gente de unas redes y de otras no | La red que falla bloquea el puerto: §4.5 (prueba) y §9.13 (puerto 443). |
| Desde la misma universidad entran ~40 y el resto no | Límite anti-flood de 40 conexiones por IP. Súbelo en `scripts/firewall.sh` (`--connlimit-above`) y ejecuta `sudo install -m 0755 scripts/firewall.sh /usr/local/sbin/minecraft-firewall.sh && sudo systemctl restart minecraft-firewall`. |
| *You are not whitelisted* | `./scripts/whitelist.sh agregar Nick` (nick exacto). |
| *Failed to verify username* | Problema de sesión del jugador o caída de los servidores de Microsoft. Si les pasa a todos a la vez, espera. |
| *Incompatible client* | §4.3. |
| Bedrock: el servidor no aparece / *Unable to connect to world* | 1) Reglas UDP 19132, TCP 19132 y UDP 19133 en la Security List (§8.5). 2) En la VM: `sudo iptables -L INPUT -n` debe incluir esos puertos (si no, repite `bootstrap-host.sh`). 3) `docker compose logs mc \| grep -i geyser` debe mostrar *Started Geyser on UDP port 19132*. |
| Bedrock: *You are not whitelisted* | `./scripts/whitelist.sh bedrock "Gamertag"` (después de un primer intento de entrar). |

### 13.3 Rendimiento (lag)

1. ¿Es lag de red o de servidor? `./scripts/console.sh tps`: si TPS ≈ 20, el problema es la conexión del jugador.
2. Si TPS < 18, perfila: `./scripts/console.sh "spark profiler start"`, espera 3 minutos con el lag ocurriendo, `./scripts/console.sh "spark profiler stop"` → abre el enlace: muestra qué consume el tiempo (un plugin, un tipo de entidad, una zona).
3. Causas típicas y soluciones:
   - **Generación de terreno** (jugadores explorando lejos): pregenerar y borde (§8.13).
   - **Demasiadas entidades** (granjas, ítems en el suelo): `./scripts/console.sh "minecraft:kill @e[type=item]"`; hablar con el dueño de la granja.
   - **Poca RAM / mucho swap** (`free -h` muestra mucho *swap used*): baja `MC_MEMORY` 1 GB.
   - **Demasiada distancia**: baja `VIEW_DISTANCE` a 7 y `SIMULATION_DISTANCE` a 5 (§9.5).
4. Si con 30 jugadores normales el TPS no se mantiene, la máquina se queda corta: pasa a 4 OCPU si tu cuota lo permite, o considera un VPS (07-alternativas-y-costos.md).

### 13.4 Backups y actualizaciones

| Síntoma | Solución |
|---|---|
| No aparecen backups nuevos | `docker compose logs --tail 50 backup`. Suele ser la contraseña RCON (recrea con `docker compose up -d --force-recreate`). |
| `restore.sh` falla al extraer | El archivo está incompleto; prueba con el anterior. |
| La actualización terminó en error | `journalctl -u minecraft-update -n 100` y `docker compose logs --tail 200 mc`. Si no se arregla: `./scripts/restore.sh` con el backup previo y fija `MC_VERSION` a la versión que funcionaba. |

---

## 14. Referencia técnica

### 14.1 Variables de `.env`

| Variable | Por defecto | Significado |
|---|---|---|
| `COMPOSE_FILE` | (comentada) | Si se activa con `docker-compose.vanilla.yml`, usa el servidor oficial (§12) |
| `TZ` | `America/Mexico_City` | Zona horaria (logs, horarios de backup) |
| `MC_VERSION_AUTO` | `true` | Usar la versión más nueva que soporten todos los plugins (ignora `MC_VERSION`) |
| `MC_VERSION` | `LATEST` | Versión fija del servidor (solo si `MC_VERSION_AUTO=false`) |
| `MOTD` | texto | Mensaje bajo el nombre del servidor en la lista. `§a`, `§e`... son colores |
| `MAX_PLAYERS` | `40` | Máximo de jugadores conectados a la vez |
| `DIFFICULTY` | `normal` | `peaceful`, `easy`, `normal`, `hard` |
| `VIEW_DISTANCE` | `8` | Distancia de visión en chunks (§1.1) |
| `SIMULATION_DISTANCE` | `6` | Distancia de simulación en chunks |
| `MC_MEMORY` | `8G` | Heap de Java (§1.3) |
| `CONTAINER_MEM_LIMIT` | `10g` | Límite de RAM del contenedor (heap + ~2 GB) |
| `SERVER_OWNER` | — | Nick del dueño: único OP y grupo `owner` |
| `WHITELIST` | — | Nicks iniciales de la whitelist (separados por comas) |
| `RCON_PASSWORD` | aleatoria | Contraseña de la consola remota interna |
| `BACKUP_INTERVAL` | `6h` | Frecuencia de backups (`30m`, `6h`, `1d`) |
| `PRUNE_BACKUPS_DAYS` | `7` | Días que se guardan los backups |

### 14.2 Scripts

| Script | Quién | Uso |
|---|---|---|
| `scripts/bootstrap-host.sh` | sudo, una vez | Prepara y asegura la VM |
| `scripts/install.sh` | admin. de sistema, una vez | Crea `.env`, arranca, aplica parches, crea roles |
| `scripts/status.sh` | admin. de sistema | Estado completo |
| `scripts/console.sh` | admin. de sistema | Consola RCON |
| `scripts/whitelist.sh` | admin. de sistema | `agregar` / `quitar` / `lista` |
| `scripts/roles.sh` | admin. de sistema | `setup` / `mod` / `admin` / `quitar` / `info` / `lista` |
| `scripts/backup-now.sh` | admin. de sistema | Backup inmediato |
| `scripts/restore.sh` | admin. de sistema (usa sudo) | Restaurar backup |
| `scripts/update.sh` | automático / manual | Actualización segura (`--ahora` sin aviso) |
| `scripts/sysadmins.sh` | sudo | `agregar` / `quitar` / `lista` administradores de sistema |
| `scripts/firewall.sh` | root (systemd) | Reglas anti-flood |
| `scripts/lib.sh` | — | Funciones comunes (no se ejecuta directamente) |
| `tests/load/run-load-test.sh` | admin. de sistema | Prueba de carga con bots |

### 14.3 Archivos y carpetas

| Ruta | Contenido | En git |
|---|---|---|
| `docker-compose.yml` | Definición de los contenedores | Sí |
| `docker-compose.vanilla.yml` | Cambios para el modo vanilla | Sí |
| `docker-compose.override.yml` | Personalizaciones locales (opcional) | No |
| `.env.example` / `.env` | Plantilla / configuración real con secretos | Sí / **No** |
| `config/patches/` | Ajustes de Paper (anti-xray, entidades) | Sí |
| `data/` | Mundo, plugins, logs, `ops.json`, `whitelist.json`, `server.properties` | No |
| `data/plugins/LuckPerms/` | Base de datos de roles | No |
| `data/plugins/CoreProtect/` | Registro de bloques | No |
| `backups/` | Backups `.tar.zst` | No |
| `systemd/` | Plantillas de servicios (se instalan en `/etc/systemd/system/`) | Sí |
| `/usr/local/sbin/minecraft-firewall.sh` | Copia del firewall propiedad de root | — |
| `/etc/ssh/sshd_config.d/99-minecraft-hardening.conf` | Endurecimiento SSH | — |
| `/etc/fail2ban/jail.d/sshd.local` | Configuración de fail2ban | — |

> `server.properties` se **regenera** desde `.env` en cada arranque: cambia la configuración en `.env`, no ahí.

### 14.4 Puertos

| Puerto | Protocolo | Expuesto a | Uso |
|---|---|---|---|
| 22 | TCP | Internet (cualquier IP), solo llaves + fail2ban | SSH (administradores de sistema) |
| 25565 | TCP | Internet (cualquier IP), con anti-flood | Minecraft Java |
| 443 | TCP | Opcional (§9.13) | Minecraft por puerto alternativo |
| 19132 | UDP | Internet (cualquier IP) | Minecraft Bedrock, conexión clásica (RakNet) |
| 19132 | TCP | Internet (cualquier IP) | Minecraft Bedrock, señalización NetherNet |
| 19133 | UDP | Internet (cualquier IP) | Minecraft Bedrock, conexión nueva (NetherNet) |
| 25575 | TCP | **Solo red interna de Docker** | RCON |

### 14.5 Permisos por rol

| Rol | Permisos (además de los heredados) |
|---|---|
| `default` | `essentials.`: `spawn home sethome delhome tpa tpaccept tpdeny back msg reply mail mail.send afk list motd rules helpop ignore seen` |
| `moderador` | `essentials.`: `kick(.notify) mute(.notify .offline) tempban(.offline) ban.notify unban jail jails togglejail jail.notify tp tphere tpo vanish invsee socialspy whois helpop.receive broadcast gamemode gamemode.spectator gamemode.survival`; `coreprotect.`: `inspect lookup rollback restore`; `spark.tps spark.healthreport bukkit.command.tps minecraft.command.whitelist` |
| `admin` | `*` (todo) **excepto** `luckperms.*`, `minecraft.command.op`, `minecraft.command.deop`, `essentials.sudo.exempt` |
| `owner` | `*` incluido `luckperms.*` |

Definidos en `scripts/roles.sh` (función `setup`).

### 14.6 Servicios systemd

| Unidad | Función |
|---|---|
| `minecraft.service` | Levanta los contenedores al arrancar la VM |
| `minecraft-firewall.service` | Aplica las reglas anti-flood al arrancar |
| `minecraft-update.service` | Ejecuta `update.sh` |
| `minecraft-update.timer` | Dispara la actualización cada lunes 05:00 (±15 min) |

Comandos: `systemctl status <unidad>`, `journalctl -u <unidad>`.

### 14.7 Componentes de software

| Componente | Sitio |
|---|---|
| Imagen del servidor | <https://github.com/itzg/docker-minecraft-server> · docs: <https://docker-minecraft-server.readthedocs.io> |
| Imagen de backups | <https://github.com/itzg/docker-mc-backup> |
| Paper | <https://papermc.io> |
| LuckPerms | <https://luckperms.net/wiki> |
| EssentialsX | <https://essentialsx.net/wiki> |
| CoreProtect | <https://docs.coreprotect.net> |
| spark (incluido en Paper) | <https://spark.lucko.me/docs> |
| Chunky | <https://modrinth.com/plugin/chunky> |
| LPC (formato de chat con prefijos) | <https://modrinth.com/plugin/lpc-chat> |
| ViaVersion / ViaBackwards | <https://viaversion.com> |

---

## 15. Preguntas frecuentes

**¿Funciona con la versión oficial de Minecraft Java?**
Sí. Los jugadores usan el Minecraft Java Edition oficial, sin instalar nada. Además, el servidor exige cuentas oficiales (online-mode). Si se necesita también el *servidor* oficial de Mojang, ver §12.

**¿Pueden entrar desde sus casas?**
Sí, desde cualquier IP y red con internet: el puerto 25565 está abierto a `0.0.0.0/0`. Lo que decide quién entra es la **whitelist** (por nick), no la IP. Solo algunas redes muy restrictivas bloquean el puerto (§9.13).

**¿Cuántos jugadores soporta?**
En la prueba real, 90 bots con 20 TPS usando 2 núcleos. Para jugadores reales, ~50–70 con la VM gratuita de 2 OCPU/12 GB y ~100 con 4 OCPU/24 GB (§3).

**¿Pueden entrar jugadores de Bedrock (móvil, Windows, consola)?**
Sí: Geyser y Floodgate vienen instalados. Entran por el puerto 19132 con su cuenta de Xbox/Microsoft, sin comprar Java, y juegan en el mismo mundo (§4.7). Las consolas necesitan un truco extra (*BedrockConnect*). No disponible en modo vanilla.

**¿Pueden entrar jugadores con Minecraft no oficial (pirata)?**
No. Es intencionado: con online-mode desactivado cualquiera podría entrar con el nick del dueño.

**¿Cuánto cuesta?**
0 $ con Oracle Always Free. Ver [07-alternativas-y-costos.md](07-alternativas-y-costos.md).

**¿Se pierde el mundo si se reinicia o actualiza?**
No. El mundo está en `data/`, fuera del contenedor, y hay backups cada 6 h.

**¿Los jugadores de Bedrock cuentan para el límite de jugadores?**
Sí, `MAX_PLAYERS` cuenta a todos. Cada jugador de Bedrock consume algo más de CPU que uno de Java (Geyser traduce su conexión).

**¿Puedo instalar más plugins?**
Sí, mientras estén en Modrinth y sean para Paper (§9.10). Cada plugin consume recursos; añade solo lo necesario.

**¿Por qué no dar OP a los moderadores?**
Porque OP permite todo, incluido dar OP a otros. Los roles de LuckPerms aplican el principio de mínimo privilegio (§1.4).

**¿Quién puede ver los mensajes privados?**
Los moderadores con `/socialspy` y los administradores de sistema en los logs. Infórmalo en las reglas del servidor.
