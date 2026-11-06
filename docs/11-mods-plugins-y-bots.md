# 11. Mods, plugins y bots

Cómo ampliar el servidor: añadir funciones (plugins), contenido extra (datapacks), qué pasa con los mods, y bots para administrar el servidor desde Discord o para hacer pruebas.

---

## 1. Plugins, mods, datapacks... ¿qué es cada cosa?

| Tipo | Dónde se instala | ¿Los jugadores instalan algo? | ¿Funciona en este servidor (Paper)? | Ejemplos |
|---|---|---|---|---|
| **Plugin** | Solo en el servidor | **No** | **Sí** | Roles, protección de zonas, mapas web, bot de Discord |
| **Datapack** | Solo en el mundo del servidor | **No** | **Sí** | Recetas nuevas, mecánicas de Vanilla Tweaks, estructuras |
| **Resource pack** | En el cliente (el servidor puede ofrecerlo) | Se descarga solo al entrar | Sí | Texturas, sonidos |
| **Mod de cliente** (solo visual o de ayuda) | Solo en el cliente | Quien quiera | **Sí**, el servidor ni se entera | Sodium/OptiFine (rendimiento), shaders, minimapa |
| **Mod de servidor y cliente** (Forge, Fabric, NeoForge) | Servidor **y todos** los clientes | **Sí, los mismos mods** | **No** (ver §5) | Mods de tecnología, magia, nuevos bloques/mobs |

**Recomendación para este proyecto:** usar **plugins y datapacks**. Los jugadores (incluidos los de TLauncher y Bedrock) entran sin instalar nada.

## 2. Añadir plugins

Los plugins se descargan de [Modrinth](https://modrinth.com/plugins). El script comprueba que el plugin tenga una versión **estable para Paper y para la versión de Minecraft del servidor** antes de instalarlo, para que un plugin nunca impida arrancar ni obligue a bajar de versión el mundo.

Buscar (solo muestra compatibles):

```bash
./scripts/plugins.sh buscar "proteger zonas"
```

Instalar (el nombre es el *slug*, lo que aparece en la URL `modrinth.com/plugin/<slug>`). Reinicia el servidor (2–3 min):

```bash
./scripts/plugins.sh agregar worldedit
```

Quitar (conserva su configuración en `data/plugins/`):

```bash
./scripts/plugins.sh quitar worldedit
```

Ver base + adicionales + cargados:

```bash
./scripts/plugins.sh lista
```

Los plugins adicionales quedan en `EXTRA_PLUGINS` de `.env` (separados por comas), se actualizan solos en cada reinicio y entran en los backups.

### Plugins recomendados (compatibles con el servidor en noviembre de 2026)

| Slug | Para qué | Notas |
|---|---|---|
| `worldedit` | Construir/editar zonas grandes (`//wand`, `//set`, `//copy`) | Solo admins (permiso `worldedit.*`, ya incluido en `admin` y `owner`) |
| `worldguard` | Proteger zonas (spawn, edificios de la clase) con `/rg define` | Requiere `worldedit` |
| `bluemap` | Mapa 3D del mundo en el navegador | Usa bastante CPU al renderizar y necesita abrir el puerto 8100 (§2.1) |
| `discordsrv` | Bot de Discord (§4) | Instálalo con `./scripts/discord.sh` |
| `simple-voice-chat` | Chat de voz por proximidad | Cada jugador instala el mod de voz en su cliente y hay que abrir UDP 24454 (§2.1) |

> Cada plugin consume RAM y CPU. En la máquina de 4 GB de Azure, añade solo lo necesario y vigila con `./scripts/status.sh`.

### 2.1 Plugins que necesitan un puerto extra

Algunos (BlueMap, Simple Voice Chat) usan un puerto propio. Hay que abrirlo en **tres sitios**:
1. **Docker:** en `docker-compose.override.yml` (no se sube a git):
```yaml
services:
  mc:
    ports:
      - "8100:8100/tcp"      # BlueMap
      - "24454:24454/udp"    # Simple Voice Chat
```
2. **Firewall de la VM:** `sudo ufw allow 8100/tcp` (o `24454/udp`).
3. **Firewall de la nube:** en Azure, en Cloud Shell: `az network nsg rule create -g minecraft30 --nsg-name minecraft30-nsg -n BlueMap --priority 350 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 8100` (en Oracle, una regla más en la Security List).

Luego `docker compose up -d mc`. Si usas `COMPOSE_FILE` en `.env` (modos vanilla o no premium), añade `:docker-compose.override.yml` al final.

## 3. Datapacks

Un datapack es una carpeta o `.zip` con recetas, funciones o cambios de mecánicas que entiende el Minecraft "vanilla": no hace falta ningún plugin ni que los jugadores instalen nada. Fuentes: [Vanilla Tweaks](https://vanillatweaks.net/picker/datapacks/) (eliges y descargas un `.zip`) o [Modrinth → Data Packs](https://modrinth.com/datapacks).

1. Copia el `.zip` desde tu PC a la VM:
```bash
scp -i "$env:USERPROFILE\.ssh\minecraft30_key.pem" .\mi-datapack.zip azureuser@IP_PUBLICA:/tmp/
```
2. En la VM, muévelo a la carpeta de datapacks del mundo y recarga:
```bash
sudo mv /tmp/mi-datapack.zip data/world/datapacks/ && sudo chown 1000:1000 data/world/datapacks/mi-datapack.zip && ./scripts/console.sh "minecraft:reload"
```
3. Comprueba: `./scripts/console.sh "datapack list"`.

Para quitarlo: `./scripts/console.sh "datapack disable \"file/mi-datapack.zip\""` y borra el archivo.

## 4. Bot de Discord para administrar el servidor (DiscordSRV)

Con [DiscordSRV](https://modrinth.com/plugin/discordsrv) el servidor tiene un bot en tu servidor de Discord:
- **#minecraft-chat:** el chat del juego aparece en Discord y lo que se escribe en Discord aparece en el juego. Cualquiera puede escribir `playerlist` para ver quién está conectado.
- **#consola-admin** (privado): todo lo que escribas ahí se ejecuta **como la consola del servidor** — `whitelist add Nick`, `lp user Nick parent set moderador`, `kick Nick`, `list`, `tps`… Ideal para administrar desde el celular sin SSH.
- En #minecraft-chat se pueden ejecutar comandos con `!c <comando>` (ej. `!c kick Nick spam`):
  - Rol **Admin Minecraft**: cualquier comando.
  - Rol **Moderador Minecraft**: solo comandos de moderación (`list`, `tps`, `say`, `kick`, `mute`, `tempban`, `unban`, `whitelist`, `fwhitelist`, `co`, `seen`).
  - Los demás no pueden usar `!c`.

### Roles en Discord y en el juego

Son dos cosas separadas: el rol **del juego** (LuckPerms) decide lo que alguien puede hacer dentro de Minecraft; el rol **de Discord** decide lo que puede hacer desde Discord. Al nombrar a alguien, dale los dos:

| Persona | En el juego (consola o #consola-admin) | Rol en Discord | #consola-admin |
|---|---|---|---|
| Moderador | `lp user Nick parent set moderador` | **Moderador Minecraft** | No |
| Admin | `lp user Nick parent set admin` | **Admin Minecraft** | Sí (si confías en él: ahí tiene poder total) |

Crea el rol *Moderador Minecraft* en Discord (Ajustes del servidor → Roles) y aplica la configuración con `./scripts/discord.sh roles`.

### 4.1 Crear el bot en Discord (10 minutos)

1. Entra en <https://discord.com/developers/applications> → **New Application** → nombre (ej. "Minecraft BUAP") → **Create**.
2. Menú **Bot** → **Reset Token** → **Copy**. Es la **contraseña del bot**: no la compartas ni la subas a git. Si se filtra, vuelve a pulsar *Reset Token*.
3. En la misma página, en **Privileged Gateway Intents**, activa **SERVER MEMBERS INTENT** y **MESSAGE CONTENT INTENT** → **Save Changes**.
4. Menú **OAuth2** → **URL Generator** → *Scopes*: `bot` y `applications.commands` → *Bot permissions*: View Channels, Send Messages, Read Message History, Embed Links, Attach Files, Manage Webhooks, Use Slash Commands → copia la URL de abajo, ábrela y añade el bot a tu servidor de Discord.
5. En tu servidor de Discord:
   - Crea un rol llamado exactamente **Admin Minecraft** y dáselo a los admins.
   - Crea el canal **#minecraft-chat** (público) y **#consola-admin** (privado: solo visible para *Admin Minecraft* y el bot).
6. Activa el modo desarrollador para copiar IDs: **Ajustes de usuario → Avanzado → Modo desarrollador**. Luego clic derecho en cada canal → **Copiar ID del canal**.

### 4.2 Conectarlo al servidor

En la VM (instala DiscordSRV si hace falta, guarda la configuración y reinicia):

```bash
./scripts/discord.sh configurar "TOKEN_DEL_BOT" ID_CANAL_CHAT ID_CANAL_CONSOLA
```

Ver si se conectó:

```bash
./scripts/discord.sh estado
```

✅ El bot aparece en línea en Discord; en #consola-admin escribe `list` y debe responder con los jugadores conectados.

| Mensaje en `estado` | Solución |
|---|---|
| *The bot token is invalid* | Token mal copiado: *Reset Token* y repite `configurar` |
| *Disallowed intents* | Activa los dos *intents* del paso 4.1.3 |
| No pasa nada en los canales | IDs de canal equivocados, o el bot no tiene permiso para ver el canal |

**Quitarlo:** `./scripts/discord.sh quitar`.

> **Seguridad:** quien pueda escribir en #consola-admin controla el servidor (es la consola). Mantén ese canal privado, da el rol *Admin Minecraft* solo a personas de confianza y activa la verificación en dos pasos en tu cuenta de Discord. En modo no premium, para añadir jugadores usa mejor `./scripts/whitelist.sh agregar` desde la VM (calcula el identificador correcto).

## 5. Mods de servidor (Forge / Fabric / NeoForge)

Este servidor usa **Paper**, que ejecuta **plugins**, no mods. Los mods que añaden bloques, objetos o mobs nuevos necesitan un servidor **Fabric, Forge o NeoForge** y que **cada jugador instale exactamente los mismos mods** en su cliente.

**Qué implicaría cambiar a un servidor con mods:**

| | Paper (actual) | Fabric/NeoForge con mods |
|---|---|---|
| Jugadores instalan algo | No | Sí, el mismo paquete de mods y la misma versión |
| Bedrock (celular) | Sí | Con contenido nuevo, **no** (Bedrock no tiene esos mods) |
| Roles (LuckPerms) | Sí | Sí (tiene versión Fabric/NeoForge) |
| Moderación (EssentialsX), CoreProtect, AuthMe | Sí | **No**: habría que buscar equivalentes de cada uno |
| RAM | 4 GB alcanzan para 30 | Suele necesitar el doble o más |
| Pruebas hechas en este proyecto | Todas | Ninguna |

**Recomendación:** para un servidor de clase con 30 personas, mantener Paper con plugins y datapacks. Si el curso exige mods, hazlo como un **servidor aparte** (otro mundo, otro `.env`), no sobre el actual. La imagen usada lo soporta con `TYPE: FABRIC` (o `NEOFORGE`) y la lista de mods en `MODRINTH_PROJECTS`, y los jugadores instalarían el mismo *modpack* (TLauncher y el launcher oficial permiten instalar Fabric/Forge). Requiere su propia prueba de carga.

**Mods de cliente que sí se pueden usar** con este servidor tal cual: optimización (Sodium, OptiFine), shaders, minimapas, mejoras de interfaz. No usar mods de trampas: el anti-xray y CoreProtect los dejan en evidencia.

## 6. Bots de prueba (jugadores simulados)

Para medir cuántos jugadores aguanta el servidor sin pedir a 30 personas que entren, el proyecto incluye bots que se conectan, caminan y saltan como jugadores:
- **Prueba de carga** contra el servidor real desde tu PC: [docs/06 → "Prueba de carga contra el servidor real"](06-rendimiento.md). Usa `./scripts/prueba-carga.sh` y `./scripts/monitor.sh`.
- **Prueba automática de roles y moderación** (12 comprobaciones): `tests/load/roles-test.js`.
- **Prueba del modo no premium** (registro y login): `tests/load/authme-test.js`.

## 7. Automatizaciones que ya trabajan solas ("bots" del servidor)

| Tarea | Quién la hace | Cada cuánto |
|---|---|---|
| Backup del mundo | Contenedor `mc-backup` | 6 h (`BACKUP_INTERVAL`) |
| Actualizar Paper, plugins y sistema | `minecraft-update.timer` + `unattended-upgrades` | Lunes 05:00 / diario |
| Bloquear ataques a SSH | fail2ban | Siempre |
| Registrar quién rompe/pone cada bloque | CoreProtect | Siempre |
| Reiniciar el servidor si se cae | Docker (`restart: unless-stopped`) | Siempre |

## 8. Cómo se probó

En el servidor de pruebas: `plugins.sh agregar worldedit` y `agregar discordsrv` instalaron y cargaron los plugins (la versión siguió en 26.1.2); `agregar no-existe-xyz` fue rechazado sin tocar nada; `discord.sh configurar` escribió token, canales y rol en la configuración y, con un token falso, DiscordSRV informó *"The bot token is invalid"* sin afectar al servidor.
