# 8. Alternativa gratis: Raspberry Pi (sin tarjeta ni nube)

Si no puedes crear la cuenta de Oracle Cloud (por ejemplo, porque te rechaza la tarjeta o tu banco solo da tarjetas virtuales), puedes montar **el mismo servidor** en una Raspberry Pi en tu casa. Cuesta **0 $**; solo gastas la luz (5–7 W, unos pocos pesos al mes).

Usa los mismos Docker, scripts, roles, backups y actualizaciones automáticas que la versión de Oracle. Cambian tres cosas:

| | Oracle Cloud | Raspberry Pi |
|---|---|---|
| Dónde corre | Centro de datos de Oracle | Tu casa |
| Cómo entran los jugadores de fuera | IP pública + puerto 25565 | Túnel gratuito de **playit.gg** (sin abrir puertos del router) |
| Jugadores a la vez | 30+ | **Pi 4: ~10–20 · Pi 5: ~20–30** (estimado, con el mundo pregenerado) |
| Jugadores de Bedrock | IP pública + puerto 19132 | Segundo túnel de playit (UDP), §6 |

---

## 1. ¿Cuántos jugadores aguanta?

Minecraft depende sobre todo de la velocidad de **un** núcleo.
- **Pi 4** (Cortex-A72 a 1.5–1.8 GHz): unas 2–3 veces más lenta por núcleo que la VM de Oracle.
- **Pi 5** (Cortex-A76 a 2.4 GHz): unas 2–3 veces más rápida que la Pi 4, cerca de un núcleo de la VM de Oracle.

Estimaciones (no medidas en una Pi real; mídelo tú, ver abajo):

| Situación | Pi 4 | Pi 5 |
|---|---|---|
| Jugando cerca de la base, mundo pregenerado | 15–20 | 25–30 |
| Varios explorando terreno nuevo, granjas grandes | 8–12 | 15–20 |

**Para 30 jugadores a la vez hace falta una Pi 5 de 8 GB** (con `MAX_PLAYERS=30` en `.env`), mundo pregenerado y, mejor, un SSD. Con una Pi 4, 30 a la vez tendrán lag.

Para un servidor de clase suele alcanzar, porque casi nunca se conectan todos a la vez. Mide el rendimiento real con `./scripts/status.sh` (TPS cercano a 20 = bien; por debajo de 15 = lag) o con la prueba de carga ([06-rendimiento.md](06-rendimiento.md)), lanzando los bots **desde otra computadora** para no quitarle CPU a la Pi.

## 2. Qué necesitas

| Cosa | Requisito |
|---|---|
| Raspberry Pi | **Pi 4 o Pi 5 de 8 GB** (recomendado) o de 4 GB (menos jugadores) |
| Sistema | **Raspberry Pi OS Lite 64-bit**, Debian 12/13 o Ubuntu Server de **64 bits**. El de 32 bits no sirve |
| Disco | microSD de 32 GB o más sirve para empezar. Un **SSD por USB 3.0** (puerto azul) es más rápido y no se desgasta (§8) |
| Red | **Cable Ethernet** al router (el WiFi añade lag y cortes) |
| Enfriamiento | Disipador con ventilador. Sin él, la Pi se calienta y baja su velocidad |
| Fuente | La oficial (Pi 4: 5V/3A). Una fuente débil provoca cuelgues |

Comprueba el sistema en la Pi:

```bash
uname -m
```

Debe decir `aarch64`. Si dice `armv7l`, el sistema es de 32 bits y hay que reinstalarlo con la versión de 64 bits.

> **¿Tu Pi ya hace otras cosas (Pi-hole, cámaras, dashboards)?** No hay problema. El proyecto limita a Minecraft a **3 de los 4 núcleos** y a **5 GB de RAM** (Pi de 8 GB), así que siempre queda espacio para lo demás. El firewall que se instala **permite todo el tráfico de tu red local**, así que Pi-hole y tus paneles siguen funcionando igual.

## 3. Preparar el acceso SSH con llave

Desde tu computadora, copia tu llave pública a la Pi (cambia `usuario` e `IP_DE_LA_PI`; la IP la ves con `hostname -I` en la Pi o en el panel de tu router).

**Windows (PowerShell):**

```bash
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh usuario@IP_DE_LA_PI "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**Mac / Linux:**

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub usuario@IP_DE_LA_PI
```

Comprueba que entras **sin contraseña de la Pi** (solo la de tu llave, si le pusiste):

```bash
ssh usuario@IP_DE_LA_PI
```

> ⚠ El paso siguiente **desactiva el acceso SSH con contraseña** (solo con llave), como en Oracle. Si otros programas o personas entran a la Pi con contraseña, primero dales una llave.

**Recomendado:** en el panel de tu router, reserva una IP fija para la Pi (*DHCP reservation* / *IP estática*). Si ya usas Pi-hole como DNS, probablemente ya la tiene.

## 4. Crear la cuenta de playit.gg y la clave del agente

playit.gg crea un **túnel**: los jugadores se conectan a una dirección de playit (ej. `algo.joinmc.link`) y playit reenvía el tráfico a tu Pi por una conexión que **sale** de tu casa. Por eso:
- No hay que abrir puertos en el router.
- Funciona aunque tu internet use **CG-NAT** (muy común en México con Telmex, Izzi, Totalplay y datos móviles).
- Los jugadores **no ven la IP de tu casa**.

Pasos:
1. Entra en <https://playit.gg> y crea una cuenta gratis (sin tarjeta).
2. Ve a **Agents → Add Agent** y elige **Docker**.
3. Copia la **secret key** que aparece (una cadena larga). Es una contraseña: no la publiques ni la subas a git.

## 5. Instalar el servidor

En la Pi, por SSH:

```bash
sudo apt update && sudo apt install -y git
```

```bash
sudo git clone https://github.com/usx22/minecraft30.git /opt/minecraft30 && sudo chown -R "$USER": /opt/minecraft30
```

```bash
cd /opt/minecraft30 && sudo ./scripts/bootstrap-host.sh
```

`bootstrap-host.sh` detecta que es una Raspberry Pi y:
- Instala Docker (repositorio de Debian o Ubuntu, según tu sistema).
- Configura el firewall dejando pasar toda tu red local.
- No crea swap extra si ya hay (cuida la microSD).
- Activa el **control de memoria** del kernel (cgroup), necesario para que se respete el límite de RAM del servidor.

Al terminar te dice si hay que **reiniciar**. Hazlo (o cierra la sesión SSH y vuelve a entrar si no lo pide):

```bash
sudo reboot
```

Vuelve a entrar por SSH y ejecuta el instalador:

```bash
cd /opt/minecraft30 && ./scripts/install.sh
```

La primera vez crea `.env` a partir de **`.env.raspberrypi.example`** (valores para la Pi) y se detiene. Edítalo:

```bash
nano .env
```

Cambia:
- `PLAYIT_SECRET_KEY=` → pega la clave del paso 4.
- `SERVER_OWNER=` → tu nick de Minecraft.
- `WHITELIST=` → tu nick y los de tus compañeros, separados por coma.
- **Solo si tu Pi es de 4 GB:** `MC_MEMORY=2G` y `CONTAINER_MEM_LIMIT=2816m`.

Guarda con `Ctrl+O`, `Enter`, y sal con `Ctrl+X`. Luego vuelve a ejecutar:

```bash
./scripts/install.sh
```

La primera vez tarda bastante (10–20 min en la Pi): descarga Java, Paper y los plugins y genera el mundo.

## 6. Crear el túnel y conectarse

1. En <https://playit.gg>, en **Agents**, tu agente debe aparecer como **conectado** (en línea).
2. Ve a **Tunnels → Add Tunnel**:
   - Tipo: **Minecraft Java (game)**.
   - Agente: el tuyo.
   - Dirección local: **`127.0.0.1`**, puerto **`25565`**.
3. Crea el túnel. playit te muestra la dirección pública, por ejemplo `algo.gl.joinmc.link`.

**Túnel para jugadores de Bedrock** (móvil, Windows): crea un segundo túnel:
   - Tipo: **Minecraft Bedrock (game)** (es UDP).
   - Dirección local: **`127.0.0.1`**, puerto **`19132`**.

   playit te da una dirección y un **puerto** propios (ej. `algo.gl.at.ply.gg`, puerto `12345`): los jugadores de Bedrock ponen ambos en **Agregar servidor**. Por el túnel funciona el método de conexión clásico (RakNet); el resto (whitelist de Bedrock, nombres `.Gamertag`) es igual que en el [MANUAL §4.7](MANUAL.md#47-entrar-desde-minecraft-bedrock-móvil-windows-consolas).

**Cómo se conecta cada quien:**

| Desde | Dirección en Minecraft |
|---|---|
| Java, fuera de tu casa (compañeros, datos móviles, universidad) | La dirección de playit, ej. `algo.gl.joinmc.link` |
| Bedrock, fuera de tu casa | La dirección **y el puerto** del túnel de Bedrock |
| Tu misma red de casa (Java o Bedrock) | `IP_DE_LA_PI` (ej. `192.168.1.50`), sin túnel y con menos lag |

**Diferencias con Oracle que hay que saber:**
- Todos los jugadores que entran por el túnel aparecen con la **misma IP** (la del túnel). Por eso **nunca uses `/banip`**: banearía a todos. Banea por nick (`/ban Nick`), como ya indica el [MANUAL §6.4](MANUAL.md#64--no-banear-por-ip).
- Las reglas anti-flood de `firewall.sh` no se aplican al tráfico del túnel (llega desde la propia Pi). playit filtra ataques por su lado, y la whitelist sigue decidiendo quién entra.
- El túnel gratuito añade algo de latencia (normalmente 20–60 ms), porque el tráfico pasa por los servidores de playit.

## 7. Pregenerar el mundo (muy recomendado en la Pi)

Generar terreno nuevo es lo que más lag causa en la Pi. Pregenera un radio de 2000 bloques (déjalo corriendo de noche):

```bash
./scripts/console.sh "chunky radius 2000"
```

```bash
./scripts/console.sh "chunky start"
```

Progreso (en la Pi tarda unas horas):

```bash
./scripts/console.sh "chunky progress"
```

Cuando termine, pon el borde para que no se genere más terreno:

```bash
./scripts/console.sh "worldborder set 4000"
```

## 8. Backups fuera de la Pi y cuidado del disco

Los backups automáticos se guardan en `backups/` **dentro de la misma microSD**. Si la tarjeta se daña, se pierde todo. Copia los backups fuera de la Pi; lo más fácil es Google Drive (15 GB gratis) con rclone:

```bash
sudo apt install -y rclone && rclone config
```

Crea un *remote* llamado `nube` de tipo Google Drive (rclone te da un enlace para autorizar desde tu computadora). Después añade la copia automática:

```bash
crontab -e
```

Y pega al final:

```
45 */12 * * * rclone copy /opt/minecraft30/backups nube:minecraft-backups --max-age 13h
```

Más detalles en [docs/05](05-actualizaciones-y-backups.md).

**microSD vs SSD:** el servidor escribe el mundo cada pocos minutos, y las microSD se desgastan con eso. Para empezar sirve, pero si el servidor se va a usar mucho, cambia a un SSD por USB 3.0. Para mover todo a otra tarjeta o a un SSD, sigue "Migrar a otra máquina" en [docs/07](07-alternativas-y-costos.md#migrar-a-otra-máquina).

## 9. Revisar que la Pi va bien

Estado del servidor (jugadores, TPS, RAM, backups):

```bash
./scripts/status.sh
```

Consumo de cada contenedor (CPU y RAM):

```bash
docker stats --no-stream
```

Temperatura (por debajo de 70 °C está bien):

```bash
vcgencmd measure_temp
```

¿Se está frenando por calor o por mala alimentación? (`throttled=0x0` = todo bien):

```bash
vcgencmd get_throttled
```

¿Docker respeta el límite de memoria? (debe decir `5368709120`, es decir 5 GB; si dice `0`, falta reiniciar tras `bootstrap-host.sh`):

```bash
docker inspect -f '{{.HostConfig.Memory}}' mc
```

Estado del túnel:

```bash
docker compose logs --tail 30 playit
```

> La actualización semanal (lunes 05:00) reinicia el servidor de Minecraft, y las actualizaciones de seguridad pueden reiniciar la Pi a las 05:30. Si usas Pi-hole, el DNS de la casa se corta un par de minutos en ese momento.

## 10. Solución de problemas

| Problema | Causa probable | Solución |
|---|---|---|
| `install.sh` dice "Falta PLAYIT_SECRET_KEY" | No pegaste la clave en `.env` | Paso 5 |
| El agente no aparece conectado en playit.gg | Clave mal copiada | Revisa `docker compose logs playit`, corrige `.env` y ejecuta `docker compose up -d` |
| Desde fuera no conecta, desde casa sí | Túnel mal creado | El túnel debe ser *Minecraft Java* hacia `127.0.0.1:25565` |
| Lag con pocos jugadores | Terreno sin pregenerar, calor o microSD lenta | §7, revisa la temperatura (§9), considera un SSD |
| El internet de la casa va lento cuando hay jugadores | La Pi también es el DNS (Pi-hole) y está saturada | Baja `CONTAINER_CPUS=2` en `.env` y ejecuta `docker compose up -d` |
| El servidor se reinicia solo | Se quedó sin memoria | Baja `MC_MEMORY` (y `CONTAINER_MEM_LIMIT`) en `.env` |
| `bootstrap-host.sh` dice "Se necesita un sistema de 64 bits" | Sistema de 32 bits | Reinstala Raspberry Pi OS **64-bit** |

## 11. Para el informe: qué conceptos del curso se ven aquí

- **NAT y CG-NAT:** por qué un servidor en casa normalmente no es accesible desde internet, y cómo un **túnel saliente** (playit) lo resuelve sin abrir puertos.
- **cgroups:** el kernel de Linux limita la CPU (`cpus: 3`) y la RAM (`mem_limit`) de cada contenedor; en la Pi hubo que activarlo en `cmdline.txt`.
- **Firewall por zonas:** la red local es de confianza; el resto, denegado por defecto.
- **Arquitecturas:** el mismo proyecto corre en x86 y ARM64 porque las imágenes de Docker son multi-arquitectura.
