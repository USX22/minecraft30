# Tutorial paso a paso: de cero a servidor funcionando y probado

Este tutorial es **lineal**: una sola lista de pasos, en orden, que cualquier persona puede seguir sin importar su rol. Lleva desde no tener nada hasta tener el servidor instalado **y verificado** (jugadores, roles, acceso desde otras redes, reinicios, backups, actualizaciones, seguridad y carga).

- Cada paso dice **qué hacer**, **qué deberías ver** (✅) y **qué hacer si no sale** (❌).
- Los términos técnicos se explican en el [MANUAL §1](MANUAL.md#1-conceptos-técnicos-explicados); los detalles de cada tema, en las secciones del manual que se indican.
- Al final hay una **tabla de resultados** para copiar en el informe del proyecto.

**Necesitas:**
- Una computadora con Windows 10/11, Mac o Linux.
- Una tarjeta de crédito o débito (solo para verificar la cuenta de Oracle; no se cobra). Las tarjetas virtuales o sin datos impresos suelen ser rechazadas. **Sin tarjeta:** usa una Raspberry Pi con [docs/08-raspberry-pi.md](08-raspberry-pi.md) para la instalación y vuelve a este tutorial para las pruebas.
- Minecraft Java Edition oficial comprado.
- Para las pruebas de roles: **una segunda persona** con Minecraft (un compañero), o una segunda cuenta.
- Tiempo: ~2–3 horas (más la pregeneración del mundo, que corre sola).

**Convenciones:** los bloques de código se copian y pegan tal cual, uno por uno. Sustituye `IP_PUBLICA` por la IP de tu servidor, `TuNick` por tu nombre de Minecraft y `NickAmigo` por el de tu compañero. Los comandos que empiezan con `/` se escriben en el chat de Minecraft (tecla `T`).

---

## Parte A — Preparación en tu computadora (10 min)

### A1. Abrir una terminal
- **Windows:** tecla Windows → escribe `PowerShell` → Enter.
- **Mac:** `Cmd + Espacio` → escribe `Terminal` → Enter.
- **Linux:** abre "Terminal".

### A2. Crear tu llave SSH
```bash
ssh-keygen -t ed25519 -C "minecraft30"
```
- "Enter file in which to save the key": pulsa **Enter**.
- "Enter passphrase": escribe una contraseña (no se ve al escribir) y **Enter**; repítela.

✅ Dice `Your public key has been saved in ...id_ed25519.pub`.
❌ `ssh-keygen no se reconoce` (Windows antiguo): Configuración → Aplicaciones → Características opcionales → Agregar → **Cliente OpenSSH**.

### A3. Copiar tu llave pública
- **Windows:**
```bash
type $env:USERPROFILE\.ssh\id_ed25519.pub
```
- **Mac/Linux:**
```bash
cat ~/.ssh/id_ed25519.pub
```

✅ Una línea que empieza con `ssh-ed25519 AAAA`. Cópiala entera en un bloc de notas: la usarás en B3.

> Guarda una copia del archivo `id_ed25519` (sin `.pub`) en un USB o gestor de contraseñas. **Nunca** se lo envíes a nadie.

---

## Parte B — Crear la máquina en Oracle Cloud (20–40 min)

### B1. Crear la cuenta
1. Entra en <https://www.oracle.com/cloud/free/> → **Start for free**.
2. Rellena tus datos, verifica el correo, elige la **Home Region** más cercana a los jugadores (no se puede cambiar) y añade la tarjeta.
3. (Recomendado) **Billing & Cost Management → Upgrade and Manage Payment → Pay As You Go**. Sigue costando 0 $ con recursos gratuitos y evita que Oracle borre la VM por inactividad.
4. **Billing → Budgets → Create Budget**: 1 $ con tu correo, para enterarte si algo empieza a costar.

✅ Puedes entrar en la consola de Oracle (cloud.oracle.com).

### B2. Ver cuánto tienes gratis
Menú ☰ → **Governance & Administration → Limits, Quotas and Usage** → busca `A1`.

✅ Anota cuántas OCPU y GB de memoria A1 tienes (normalmente 2/12 o 4/24).

### B3. Crear la VM
Menú ☰ → **Compute → Instances → Create instance**:
1. **Name:** `minecraft30`.
2. **Image and shape → Edit → Change image → Ubuntu → Canonical Ubuntu 24.04** → Select.
3. **Change shape → Ampere → VM.Standard.A1.Flex** → pon el máximo de OCPU y memoria de B2 → Select.
4. **Networking:** *Create new virtual cloud network*, *Create new public subnet*, **Assign a public IPv4 address: Yes**.
5. **Add SSH keys → Paste public keys** → pega la línea de A3.
6. **Boot volume → Specify a custom boot volume size → 100**.
7. **Create**.

✅ A los 1–2 min el estado es **Running** (verde). Copia la **Public IP address**: es tu `IP_PUBLICA`.
❌ "Out of capacity": en *Placement* elige otro *Availability Domain* o reinténtalo más tarde.

### B4. Abrir el puerto de Minecraft a cualquier IP
En la página de la instancia → clic en la **Subnet** → **Security Lists** → **Default Security List** → **Add Ingress Rules**:
- Source CIDR: `0.0.0.0/0`
- IP Protocol: `TCP`
- Destination Port Range: `25565`
- Description: `Minecraft`

→ **Add Ingress Rules**.

✅ En la lista de reglas aparece una con puerto `25565` y origen `0.0.0.0/0`.

---

## Parte C — Instalar el servidor (30–40 min)

### C1. Entrar a la VM
En tu terminal:
```bash
ssh ubuntu@IP_PUBLICA
```
Responde `yes` la primera vez y escribe tu passphrase.

✅ El texto cambia a algo como `ubuntu@minecraft30:~$`. Ahora todo lo que escribas se ejecuta **en el servidor**.
❌ `Permission denied (publickey)`: la llave pegada en B3 no coincide. ❌ `timed out`: revisa la IP y que la VM esté Running.

### C2. Descargar el proyecto
```bash
sudo git clone https://github.com/usx22/minecraft30.git /opt/minecraft30 && sudo chown -R "$USER": /opt/minecraft30
```
```bash
cd /opt/minecraft30
```

✅ `ls` muestra `README.md`, `docker-compose.yml`, `scripts`, `docs`...
❌ Pide usuario/contraseña: el repositorio es privado; usa un token como contraseña ([MANUAL §8.7](MANUAL.md#87-descargar-el-proyecto)). ❌ La carpeta está vacía: los archivos aún no están en la rama principal (`main`) del repositorio; fusiona la rama del proyecto o clona con `-b nombre-de-la-rama`.

### C3. Preparar y asegurar la VM
```bash
sudo ./scripts/bootstrap-host.sh
```

✅ Tras 5–10 min termina con `Listo. Cierra la sesión SSH y vuelve a entrar...`.
❌ Si se corta, vuelve a ejecutarlo: es seguro repetirlo.

### C4. Volver a entrar
```bash
exit
```
```bash
ssh ubuntu@IP_PUBLICA
```
```bash
cd /opt/minecraft30
```
```bash
docker ps
```

✅ `docker ps` muestra una tabla vacía (sin error de permisos).

### C5. Crear y editar la configuración
```bash
./scripts/install.sh
```
✅ Dice `.env creado con contraseña RCON aleatoria` y te pide editarlo.

```bash
nano .env
```
Cambia estas líneas (muévete con las flechas):
- `SERVER_OWNER=TuNick`
- `WHITELIST=TuNick`
- `TZ=` tu zona horaria (ej. `America/Bogota`, `America/Lima`, `Europe/Madrid`)
- Si en B2 tenías 4 OCPU/24 GB: `MC_MEMORY=12G` y `CONTAINER_MEM_LIMIT=14g`. Con 2/12 déjalo como está.

Guarda: `Ctrl+O`, `Enter`. Sal: `Ctrl+X`.

### C6. Instalar y arrancar
```bash
./scripts/install.sh
```

✅ Pasa por *Descargando imágenes → Arrancando → Reiniciando para aplicar parches → Creando roles* y termina con **¡Servidor listo!** (5–15 min la primera vez).
❌ Si se detiene con error, mira el motivo:
```bash
docker compose logs --tail 100 mc
```
y busca el mensaje en el [MANUAL §13](MANUAL.md#13-solución-de-problemas).

### C7. Estado
```bash
./scripts/status.sh
```

✅ `Salud: healthy`, jugadores `0`, TPS cercano a `20`.

---

## Parte D — Primera conexión como jugador (5 min)

### D1. Entrar
1. Abre el **launcher oficial** de Minecraft → **Jugar** (Java Edition).
2. **Multijugador → Agregar servidor** → Dirección: `IP_PUBLICA` → **Listo** → **Unirse**.

✅ Entras al mundo. Escribe `hola` en el chat: tu nombre aparece como **`[Dueño] TuNick`** (en dorado).
❌ *Connection timed out*: revisa B4. ❌ *Not whitelisted*: el nick de `.env` no es exacto (mayúsculas incluidas); corrígelo con `./scripts/whitelist.sh agregar TuNick`.

### D2. Comprobar tu rol
```
/lp user TuNick info
```
✅ Muestra el grupo **owner**.

### D3. Comprobar plugins
```
/plugins
```
✅ En verde (7): Chunky, CoreProtect, Essentials, LPC, LuckPerms, ViaBackwards, ViaVersion. (spark no aparece porque viene incluido dentro de Paper: prueba `/spark tps`.)
❌ Si alguno sale en rojo o falta: `docker compose logs mc | grep -i NombreDelPlugin` (suele ser que aún no es compatible con una versión de Minecraft recién salida; ver [MANUAL §13.1](MANUAL.md#131-instalación-y-arranque)).

---

## Parte E — Probar roles y moderación (20 min, con un compañero)

> **Alternativa automática:** `tests/load/roles-test.js` hace todas las comprobaciones de esta parte (y F2) con tres bots, en un servidor de prueba en modo offline (ver [06-rendimiento.md](06-rendimiento.md)). Con el servidor de prueba arrancado: `cd tests/load && npm install && node roles-test.js` → debe terminar con `12/12 pruebas superadas`. Aun así, haz la prueba manual con personas reales al menos una vez.

### E1. Dar acceso al compañero
En la VM:
```bash
./scripts/whitelist.sh agregar NickAmigo
```
✅ `Added NickAmigo to the whitelist`. El compañero entra siguiendo D1, **desde su casa** (esto prueba también el acceso desde otra red).

### E2. Un jugador normal no puede moderar
El compañero escribe:
```
/kick TuNick
```
✅ Recibe un mensaje de que no tiene permiso.

### E3. Hacerlo moderador
En la VM (o tú en el chat con `/lp user NickAmigo parent set moderador`):
```bash
./scripts/roles.sh mod NickAmigo
```
✅ Su nombre aparece como **`[Mod] NickAmigo`** (si no cambia, que salga y vuelva a entrar).

### E4. Probar sanciones (el compañero como moderador)
1. Necesitas un "infractor" sin privilegios. Si hay una tercera persona, úsala (sustituye `TuNick` por su nick). Si no, conviértete tú temporalmente en jugador normal: quítate el OP **y** el rol (el dueño y los admins son inmunes a sanciones, por eso hay que quitar ambos). Lo restauras en E7:
```bash
./scripts/console.sh "deop TuNick"
```
```bash
./scripts/roles.sh quitar TuNick
```
2. El moderador ejecuta `/mute TuNick 1m prueba` → ✅ no puedes escribir en el chat durante 1 minuto.
3. `/kick TuNick prueba` → ✅ te expulsa con el motivo.
4. `/tempban TuNick 2m prueba` → ✅ al intentar entrar ves que estás baneado; tras 2 minutos puedes entrar (o el moderador hace `/unban TuNick`).

### E5. Probar el registro y la reversión de destrozos
1. Tú (como jugador normal) rompe 10 bloques de algo construido y pon otros 5.
2. El moderador: `/co i` y clic izquierdo en uno de esos bloques → ✅ muestra tu nombre, la acción y la hora.
3. El moderador: `/co rollback u:TuNick t:10m r:20` → ✅ todo vuelve a como estaba.

### E6. Un admin no puede ascenderse a sí mismo
```bash
./scripts/roles.sh admin NickAmigo
```
El compañero (ahora `[Admin]`) intenta:
```
/lp user NickAmigo parent set owner
```
```
/op NickAmigo
```
✅ Ambos comandos son **rechazados** por falta de permiso (prueba el principio de mínimo privilegio).

### E7. Restaurar roles
```bash
./scripts/console.sh "op TuNick"
```
```bash
./scripts/roles.sh setup
```
```bash
./scripts/roles.sh quitar NickAmigo
```
✅ Tú vuelves a `[Dueño]` con OP (setup reasigna el dueño de `.env`) y el compañero a jugador normal.

---

## Parte F — Probar acceso desde distintas redes (10 min)

Repite la conexión (D1) desde redes distintas y anota el resultado:
1. Desde una **casa** (Wi-Fi doméstico).
2. Desde **datos móviles** (comparte internet del móvil al PC).
3. Desde la **red de la universidad**.

Si alguna falla con *timed out*, comprueba desde esa red si el puerto es alcanzable:
- Windows:
```bash
Test-NetConnection IP_PUBLICA -Port 25565
```
- Mac/Linux:
```bash
nc -vz IP_PUBLICA 25565
```
✅ `TcpTestSucceeded : True` / `succeeded`. Si da `False` solo en una red, esa red bloquea el puerto: habilita el puerto alternativo 443 ([MANUAL §9.13](MANUAL.md#913-puerto-alternativo-para-redes-que-bloquean-el-25565)).

### F2. Una cuenta no autorizada no entra
Pide a alguien **que no esté en la whitelist** que intente entrar.
✅ Ve *You are not whitelisted on this server*.

---

## Parte G — Probar el funcionamiento continuo (15 min)

### G1. Caída del proceso
Simula que el servidor se "cuelga" y muere (en la VM):
```bash
sudo kill -9 "$(docker inspect -f '{{.State.Pid}}' mc)"
```
Espera 2–3 minutos y:
```bash
./scripts/status.sh
```
✅ Vuelve a estar `healthy` sin que hicieras nada (Docker lo reinició). En Minecraft puedes volver a entrar.

### G2. Reinicio de la máquina
```bash
sudo reboot
```
Espera 3–4 minutos, vuelve a entrar por SSH (C1) y:
```bash
cd /opt/minecraft30 && ./scripts/status.sh
```
✅ `healthy`, y el mundo conserva lo que construiste.

---

## Parte H — Probar backups y restauración (15 min)

### H1. Marca de prueba
En Minecraft, en un lugar visible, pon un bloque de oro y un cartel que diga `BACKUP`.

### H2. Backup
```bash
./scripts/backup-now.sh
```
✅ Muestra un archivo nuevo `world-...tar.zst` en `backups/`.

### H3. "Desastre"
En Minecraft rompe el bloque de oro y el cartel.

### H4. Restaurar
```bash
./scripts/restore.sh
```
Copia el nombre del backup de H2 y:
```bash
./scripts/restore.sh backups/NOMBRE-DEL-ARCHIVO.tar.zst
```
Escribe `si` y espera a que termine.

✅ Al entrar, el bloque de oro y el cartel **están de vuelta**.

### H5. Backups automáticos
Pasadas 6 h desde la instalación:
```bash
ls -lt backups | head
```
✅ Aparecen backups creados automáticamente cada 6 h.

---

## Parte I — Probar la actualización (10 min)

```bash
./scripts/update.sh --ahora
```
✅ Hace un backup, descarga imágenes, reinicia y termina con **Actualización completada. Servidor en línea.**

Comprueba la actualización automática semanal:
```bash
systemctl list-timers minecraft-update.timer
```
✅ Muestra la próxima ejecución (lunes ~05:00).

> Para probar el aviso en el chat, ejecuta `./scripts/update.sh` (sin `--ahora`) con alguien conectado: ✅ recibe avisos a los 5 min, 1 min y 10 s.

---

## Parte J — Probar la seguridad (15 min)

### J1. Puertos abiertos
```bash
sudo ss -tlnp
```
✅ Aparecen el **22** y el **25565**. El **25575 (RCON) NO** aparece escuchando en `0.0.0.0`.

Desde **tu computadora**:
```bash
nc -vz IP_PUBLICA 25575
```
(Windows: `Test-NetConnection IP_PUBLICA -Port 25575`) ✅ Falla: RCON no es accesible desde internet.

### J2. SSH sin contraseña
Desde tu computadora, intenta entrar forzando contraseña:
```bash
ssh -o PubkeyAuthentication=no ubuntu@IP_PUBLICA
```
✅ `Permission denied (publickey)`: no acepta contraseñas.

### J3. Contenedor sin privilegios
```bash
docker inspect mc --format 'Usuario: {{.Config.User}} | Capabilities eliminadas: {{.HostConfig.CapDrop}}'
```
✅ `Usuario: 1000:1000 | Capabilities eliminadas: [ALL]`.

### J4. Firewall anti-flood y fail2ban
```bash
sudo iptables -L MC-PROTECT -n -v
```
✅ Muestra las reglas `connlimit` y `hashlimit`.
```bash
sudo fail2ban-client status sshd
```
✅ `Status for the jail: sshd` (puede que ya tenga IPs bloqueadas: bots de internet intentando entrar).

### J5. Anti-xray
Con un cliente normal no se puede comprobar fácilmente. Comprueba la configuración:
```bash
grep -A2 "anti-xray" data/config/paper-world-defaults.yml
```
✅ `enabled: true`.

---

## Parte K — Prueba de carga con 35+ bots (opcional, 40 min)

Simula muchos jugadores usando un **servidor de prueba** aparte (sin whitelist, solo accesible desde la VM). Hay que detener el servidor real durante la prueba.

```bash
sudo apt install -y nodejs npm
```
```bash
docker compose down
```
```bash
./tests/load/run-load-test.sh 35
```
✅ Los bots se van conectando (`[+] bot_N conectado`) y cada 30 s se imprime `hora,jugadores,tps`. Si el TPS se mantiene ≥ 19 con 35 jugadores, la prueba se supera. Resultados en `tests/load/resultados.csv` (útil para una gráfica en el informe).

Puedes repetir con `50` para buscar el límite. Al terminar:
```bash
docker compose -f docker-compose.yml -f tests/load/docker-compose.test.yml down
```
```bash
docker compose up -d
```
✅ `./scripts/status.sh` vuelve a mostrar el servidor real `healthy`.

> Los bots corren en la misma VM y le quitan algo de CPU, así que el resultado es **conservador** (con jugadores reales el servidor rinde algo mejor).

---

## Parte L — Dejarlo listo para todos (10 min + horas en segundo plano)

### L1. Pregenerar el mundo
```bash
./scripts/console.sh "chunky radius 3000"
```
```bash
./scripts/console.sh "chunky start"
```
Ver el progreso cuando quieras:
```bash
./scripts/console.sh "chunky progress"
```
Cuando llegue al 100 %:
```bash
./scripts/console.sh "worldborder set 6000"
```

### L2. Añadir a todos los jugadores
```bash
./scripts/whitelist.sh agregar Nick1 Nick2 Nick3 Nick4
```

### L3. Nombrar el equipo
```bash
./scripts/roles.sh mod NickModerador
```
```bash
./scripts/roles.sh admin NickAdmin
```

### L4. Segundo administrador de sistema (recomendado)
La otra persona hace la Parte A en su computadora y te envía su línea `ssh-ed25519 ...`. Tú:
```bash
sudo ./scripts/sysadmins.sh agregar nombre "ssh-ed25519 AAAA...su-llave..."
```
✅ Esa persona puede entrar con `ssh nombre@IP_PUBLICA`.

### L5. Copia de backups fuera de la VM
Desde **tu computadora**, de vez en cuando (o automatízalo con rclone, [MANUAL §9.8](MANUAL.md#98-backups)):
```bash
scp -r ubuntu@IP_PUBLICA:/opt/minecraft30/backups ./backups-minecraft
```

### L6. Compartir con los jugadores
Envía a los jugadores: la dirección (`IP_PUBLICA` o tu dominio DuckDNS, [MANUAL §8.14](MANUAL.md#814-nombre-de-dominio-gratuito-opcional)), la versión de Minecraft del servidor y el enlace a la [guía del jugador](MANUAL.md#4-guía-del-jugador).

---

## Tabla de resultados (para el informe)

| # | Prueba | Resultado esperado | ¿Pasó? | Notas |
|---|---|---|---|---|
| C7 | Instalación | `healthy`, TPS ≈ 20 | ☐ | |
| D1 | Conexión con cliente oficial | Entra con prefijo `[Dueño]` | ☐ | |
| D3 | Plugins | 7 plugins en verde | ☐ | |
| E2 | Jugador sin permisos | `/kick` rechazado | ☐ | |
| E4 | Moderación | mute, kick, tempban funcionan | ☐ | |
| E5 | Anti-griefing | Rollback restaura los bloques | ☐ | |
| E6 | Sin escalada de privilegios | Admin no puede hacerse owner ni OP | ☐ | |
| F | Acceso desde casa / móvil / universidad | Entra desde las tres redes | ☐ | |
| F2 | Whitelist | Cuenta no autorizada rechazada | ☐ | |
| G1 | Recuperación ante caída | Vuelve solo en < 3 min | ☐ | |
| G2 | Recuperación ante reinicio | Vuelve solo, mundo intacto | ☐ | |
| H4 | Restauración de backup | Marca de prueba recuperada | ☐ | |
| H5 | Backups automáticos | Uno cada 6 h | ☐ | |
| I | Actualización | Termina "completada", servidor en línea | ☐ | |
| J1 | Puertos | Solo 22 y 25565 accesibles | ☐ | |
| J2 | SSH | Contraseñas rechazadas | ☐ | |
| J3 | Contenedor | Usuario 1000, capabilities `[ALL]` eliminadas | ☐ | |
| J4 | Firewall / fail2ban | Reglas activas | ☐ | |
| K | Carga (35 bots) | TPS ≥ 19 | ☐ | TPS medido: |
| — | Costo mensual (Oracle → Billing) | 0 $ | ☐ | |
