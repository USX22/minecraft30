# 9. Alternativa gratis con correo de estudiante: Azure for Students

Si Oracle no acepta tu tarjeta, **Azure for Students** da **100 $ de crédito al año sin tarjeta**, verificando que eres estudiante con tu **correo institucional**. Con eso se paga una máquina virtual en la nube con IP pública, igual que la de Oracle, durante **unos 3 meses encendida 24/7** (un semestre). El proyecto funciona sin cambios: mismos scripts, roles, backups, Bedrock y actualizaciones.

| | Oracle Always Free | Azure for Students |
|---|---|---|
| Tarjeta | Sí (verificación) | **No** (correo institucional) |
| Costo para ti | 0 $ | 0 $ (se gasta el crédito) |
| Duración | Indefinida | Mientras dure el crédito (~3 meses 24/7); se renueva cada año como estudiante |
| Máquina recomendada | 2–4 OCPU, 12–24 GB | **B2pls_v2**: 2 vCPU ARM, 4 GB |
| Jugadores | 30+ | **30–36 medidos** con 4 GB (ver abajo) |

> **Si se acaba el crédito**, Azure **desactiva la suscripción y apaga la máquina**: no te llega ninguna factura. Copia los backups fuera antes (§9).

---

## 1. ¿Qué máquina y cuánto cuesta?

Costo real de la instalación hecha para este proyecto (región **North Central US**, precios de la API de Azure, noviembre de 2026):

| Concepto | $/mes |
|---|---|
| Máquina **Standard_B2pls_v2** (2 vCPU ARM Ampere, 4 GB) — 0,0336 $/h | 24,53 |
| Disco **SSD estándar 64 GiB** (E6) | 4,80 |
| IP pública estándar | 3,65 |
| **Total** | **≈ 33 $ → los 100 $ duran ~3 meses encendida 24/7** |

Otras opciones (si la ARM no está disponible en tu región): Standard_B2als_v2 (2 vCPU AMD, 4 GB, ~27–40 $/mes según región); con 8 GB, Standard_B2ps_v2 (~49 $/mes solo la máquina). El disco *SSD prémium* costaría 10,21 $/mes: no hace falta.

**¿Alcanzan 4 GB para 30 jugadores?** Sí, lo medimos: con la configuración de 4 GB (`MC_MEMORY=2304M`, `CONTAINER_MEM_LIMIT=3300m`) y 2 núcleos, **36 jugadores (bots) se mantuvieron a 20 TPS** y la memoria estable en 2,9 GB ([RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md)). Con 2,75 GB de *heap* el sistema mató el proceso por falta de memoria: Java necesita ~0,7–0,8 GB **además** del heap. No subas `MC_MEMORY` en una máquina de 4 GB.

**CPU con créditos (máquinas "B"):** la B2pls_v2 garantiza el 30 % de sus 2 núcleos y acumula créditos cuando usa menos (hasta 864). El servidor vacío usa ~6 % (acumula) y con 36 jugadores ~40 % (gasta ~12 créditos/hora): aguanta jornadas largas de juego sin frenarse. Una máquina **recién creada tiene pocos créditos**: la pregeneración del mundo los gasta y luego sigue más lenta (§7). Se ve en el portal: máquina → **Métricas** → *CPU Credits Remaining*.

## 2. Activar Azure for Students

1. Entra en <https://azure.microsoft.com/free/students>.
2. Pulsa **Start free** / **Activar ahora** e inicia sesión con tu **correo institucional**.
3. Verifica tu identidad (teléfono) y tu condición de estudiante. **No pide tarjeta.**
4. Tendrás una suscripción **Azure for Students** con **100 $ de crédito válido 1 año** (renovable mientras seas estudiante). El saldo se ve en <https://portal.azure.com> → buscar **Education** → *Información general*.

> Microsoft da **una** oferta por estudiante. Si tienes dos correos institucionales, usa uno.

## 3. Preparar la suscripción (una sola vez)

### 3.1 Ver en qué regiones puedes crear máquinas

Las suscripciones de estudiante solo pueden usar **unas 5 regiones**, distintas para cada persona. **La lista desplegable del formulario muestra todas las regiones del mundo**, pero si eliges una no permitida (por ejemplo *Mexico Central*) Azure la rechaza al final.
1. En el portal, busca **Directiva** → menú izquierdo → **Creación** → **Tareas** (en español, *Assignments* aparece traducido como "Tareas").
2. Abre *Allowed resource deployment regions* → pestaña **Parámetros**: el valor de `listOfAllowedLocations` es tu lista.
3. Elige la más cercana a los jugadores **en la que exista la máquina**. Ejemplo real (cuenta de la BUAP): la lista era `norwayeast, northcentralus, westus, chilecentral, belgiumcentral` y la mejor fue **North Central US** (Chicago): la más barata y ~60–100 ms de ping desde el centro de México. Ojo: **North Central US** y **Central US** son regiones distintas.

### 3.2 Activar los servicios de máquinas virtuales y redes

En una suscripción nueva, los servicios de máquinas virtuales (`Microsoft.Compute`) y de redes (`Microsoft.Network`) vienen **sin registrar**. Síntoma: al elegir el tamaño, **todos** salen *"NotAvailableForSubscription"*. Se arregla una vez desde la **Cloud Shell** del portal (icono `>_` arriba a la derecha → **Bash** → "No se requiere una cuenta de almacenamiento"):

```bash
az provider register -n Microsoft.Compute --wait && az provider register -n Microsoft.Network --wait && echo LISTO
```

Tarda 1–5 minutos. Comprueba los tamaños disponibles y tu cuota en tus regiones:

```bash
for r in northcentralus westus; do echo "== $r"; az vm list-skus -l $r --resource-type virtualMachines --query '[?length(restrictions)==`0` && starts_with(name, `Standard_B2`)].name' -o tsv | tr '\n' ' '; echo; done; az vm list-usage -l northcentralus -o table | grep -iE "bps|Total Regional vCPUs"
```

(Cambia las regiones por las tuyas.) Debe aparecer `Standard_B2pls_v2` y la fila *Standard Bpsv2 Family vCPUs* con límite ≥ 2.

## 4. Crear la máquina virtual

Portal → **Máquinas virtuales** → **Crear** → **Máquina virtual de Azure**. **Rellena en este orden** (el orden importa: los tamaños ARM solo aparecen tras elegir la arquitectura):

**Pestaña Datos básicos**

| Campo | Valor |
|---|---|
| Suscripción | Azure for Students |
| Grupo de recursos | **Crear nuevo** → `minecraft30` |
| Nombre de la máquina virtual | `minecraft30` |
| Región | **(US) North Central US** (o la tuya de §3.1) |
| Opciones de disponibilidad | **No se requiere redundancia de la infraestructura** (con "zona de disponibilidad" a veces no salen los tamaños baratos) |
| Tipo de seguridad | Estándar |
| VM architecture | **Arm64** (antes de elegir tamaño) |
| Image | **Ubuntu Server 24.04 LTS – Arm64** |
| Tamaño | **Ver todos los tamaños** → busca `B2pls` → **Standard_B2pls_v2** (24,53 US$/mes) → Seleccionar |
| Tipo de autenticación | **Clave pública SSH** |
| Nombre de usuario | `azureuser` |
| Origen de clave pública SSH | **Generar un par de claves nuevo**, formato **Ed25519**, nombre `minecraft30_key` (o "Usar clave pública existente" si ya tienes una) |
| Puertos de entrada públicos | **Permitir puertos seleccionados** → **SSH (22)** (el aviso amarillo es normal: `bootstrap-host.sh` deja SSH solo con llave y con fail2ban) |

**Pestaña Discos:** el formulario propone **30 GiB** y **SSD prémium**: cámbialos a **64 GiB** y **SSD estándar** (30 GiB no alcanzan para el mundo y 7 días de backups; prémium cuesta el doble). Deja *Eliminar con VM* marcado.

**Pestaña Redes:** marca **Eliminar IP pública y NIC cuando se elimine la VM** (si no, la IP seguiría cobrando si borras la máquina). Si te deja, pon *Grupo de seguridad de red de NIC*: **Básico**; si el resumen final dice "Grupo de seguridad de red de NIC: –", no pasa nada, se resuelve en §5.

**Pestaña Administración:** **Apagado automático desactivado**. Lo demás como viene.

**Revisar y crear** → comprueba el resumen (ARM64, B2pls_v2, 64 GiB StandardSSD_LRS, apagado automático desactivado) → **Crear** → **Descargar la clave privada y crear el recurso**. El archivo `minecraft30_key.pem` **solo se puede descargar esa vez**: guárdalo en `C:\Users\TuUsuario\.ssh\` y no lo compartas. El teléfono que aparece en "Términos" lo toma Azure de la cuenta institucional; no afecta.

## 5. Abrir los puertos del juego (para cualquier IP)

Cuando termine la implementación, abre la **Cloud Shell** (`>_`, Bash) y ejecuta el script del proyecto. Crea el firewall de Azure (NSG) si el formulario no lo creó, abre **solo** SSH 22, Java 25565 TCP, Bedrock 19132 UDP/TCP y 19133 UDP, revisa también el firewall de la subred y muestra la **IP pública**:

```bash
curl -sL https://raw.githubusercontent.com/usx22/minecraft30/claude/eager-newton-q1uimf/scripts/azure-abrir-puertos.sh | bash
```

Si tus nombres son distintos: `curl -sL ... | RG=migrupo VM=mimaquina bash`. **No abras el 25575** (RCON).

## 6. Instalar el servidor

### 6.1 Entrar desde Windows

En **PowerShell** (si guardaste la llave en `.ssh`), deja la llave legible solo por tu usuario (si no, SSH se niega a usarla):

```powershell
icacls "$env:USERPROFILE\.ssh\minecraft30_key.pem" /inheritance:r /grant:r "${env:USERNAME}:R"
```

```powershell
ssh -i "$env:USERPROFILE\.ssh\minecraft30_key.pem" azureuser@IP_PUBLICA
```

La primera vez responde `yes`. Ojo: `$env:USERPROFILE` y `$env:USERNAME` se escriben **tal cual** (son variables de Windows). Si `Move-Item`/`icacls` no encuentra el archivo, búscalo con `Get-ChildItem "$env:USERPROFILE" -Recurse -Filter "*minecraft30*"`.

### 6.2 Descargar y preparar

```bash
sudo git clone https://github.com/usx22/minecraft30.git /opt/minecraft30 && sudo chown -R "$USER": /opt/minecraft30
```

(Mientras el proyecto no esté en la rama `main`, añade `-b claude/eager-newton-q1uimf` después de `clone`.)

```bash
cd /opt/minecraft30 && sudo ./scripts/bootstrap-host.sh
```

Tarda 5–10 minutos. Para que cada vez que entres por SSH estés ya en la carpeta del proyecto (si no, los `./scripts/...` dan *"No such file or directory"*):

```bash
echo 'cd /opt/minecraft30' >> ~/.bashrc
```

Sal (`exit`) y vuelve a entrar (flecha ↑ en PowerShell repite el `ssh`).

### 6.3 Configurar e instalar

```bash
./scripts/install.sh
```

La primera vez solo crea `.env`. **Tu nick de Java** es el que aparece en el launcher **junto al botón Jugar**; el nombre de arriba a la izquierda es tu cuenta de Microsoft/Xbox (tu gamertag de Bedrock). Configura todo de una vez (cambia `TU_NICK` las dos veces):

```bash
sed -i -e 's/^SERVER_OWNER=.*/SERVER_OWNER=TU_NICK/' -e 's/^WHITELIST=.*/WHITELIST=TU_NICK/' -e 's|^TZ=.*|TZ=America/Mexico_City|' -e 's/^MC_MEMORY=.*/MC_MEMORY=2304M/' -e 's/^CONTAINER_MEM_LIMIT=.*/CONTAINER_MEM_LIMIT=3300m/' -e 's/^MAX_PLAYERS=.*/MAX_PLAYERS=36/' .env && grep -E '^(SERVER_OWNER|WHITELIST|TZ|MC_MEMORY|CONTAINER_MEM_LIMIT|MAX_PLAYERS)=' .env
```

```bash
./scripts/install.sh
```

Termina con **"¡Servidor listo!"** (~5 minutos; el reinicio intermedio tarda 2–3 min, no lo cortes).

### 6.4 Primeros pasos después de instalar

1. **Entra desde Java** con la versión **"Última versión"** del launcher (no una instalación antigua o con mods) a `IP_PUBLICA`.
2. **Rol de Dueño:** si al escribir en el chat no aparece `[Dueño]` delante de tu nombre (pasa porque el instalador te asignó el rol antes de tu primera conexión), ejecuta `./scripts/roles.sh setup`: debe decir *"Verificado: 'TU_NICK' está en el grupo owner"*.
3. **Descripción del servidor** (lo que se ve en la lista; `§6`, `§7`, `§a` son colores):
```bash
sed -i 's|^MOTD=.*|MOTD=§6Servidor para BUAP §7- §aSurvival|' .env && docker compose up -d mc
```
4. **Bedrock:** `./scripts/whitelist.sh bedrock "TuGamertag"` y entra desde Bedrock (puerto 19132) mientras el comando espera (§4.7 del manual). El aviso de "ping alto" en la lista de Bedrock es habitual con Geyser: si dentro del juego responde bien, ignóralo.
5. **Pregenerar el mundo de noche** (en esta máquina recomendamos 4 × 4 km; tarda 4–8 h por los créditos de CPU):
```bash
./scripts/console.sh "chunky radius 2000"
```
```bash
./scripts/console.sh "chunky start"
```
   Al terminar (`chunky progress` = 100 %): `./scripts/console.sh "worldborder set 4000"`. Para jugar sin lag mientras tanto: `chunky pause` / `chunky continue`.

A partir de aquí todo es igual que en el [TUTORIAL](TUTORIAL.md) (partes E a L) y el [MANUAL](MANUAL.md).

### 6.5 Un nombre en vez de la IP (gratis)

Azure da gratis un nombre para la IP pública, con la forma `NOMBRE.REGION.cloudapp.azure.com`. En la **Cloud Shell** (cambia `minecraft-buap` por el nombre que quieras: minúsculas, números y guiones; debe estar libre en la región):

```bash
az network public-ip update -g minecraft30 -n minecraft30-ip --dns-name minecraft-buap --query dnsSettings.fqdn -o tsv
```

Responde con el nombre completo, por ejemplo `minecraft-buap.northcentralus.cloudapp.azure.com`:
- **Java:** se escribe ese nombre como dirección del servidor.
- **Bedrock:** ese nombre y el puerto 19132.

Para cambiarlo, repite el comando con otro `--dns-name`. Si la IP no se llama `minecraft30-ip`, consulta su nombre con `az network public-ip list -g minecraft30 -o table`.

Si prefieres un nombre más corto, sin `cloudapp.azure.com`, crea un subdominio gratis en DuckDNS apuntando a la IP (manual §8.14), o compra un dominio (~10–15 $/año) y crea un registro A hacia la IP.

## 7. Vigilar el crédito

- **Saldo:** portal → **Education** → *Overview* (o la suscripción → *Overview*).
- **Alerta:** portal → **Cost Management** → **Budgets** → *Add*: por ejemplo 30 $ al mes, con aviso al 80 % a tu correo.
- **Ahorrar crédito** en vacaciones: en la máquina, **Stop**. Una máquina detenida (*Stopped (deallocated)*) no cobra CPU, solo el disco (~5 $/mes). Para volver: **Start** (el servidor arranca solo). Ojo: mientras está detenida, el servidor no está disponible.

## 8. Diferencias con Oracle que hay que saber

| Tema | Azure |
|---|---|
| Firewall de la nube | *Network security group* (NSG), en **Networking** de la máquina (§5). Equivale a la *Security List* de Oracle |
| Usuario SSH | `azureuser` (el que elegiste), no `ubuntu` |
| Firewall de la máquina | UFW (la imagen de Azure no trae las reglas especiales de Oracle) |
| Máquinas "B" | CPU con créditos (§1). Si `./scripts/status.sh` muestra TPS bajo sin motivo, mira *CPU Credits Remaining* |
| Fin del crédito | La suscripción se desactiva y la máquina se apaga. Se renueva cada año mientras seas estudiante |

## 9. Antes de que se acabe el crédito

1. Copia los backups a tu computadora ([MANUAL §9.8](MANUAL.md#98-backups)):
```bash
scp -r azureuser@IP_PUBLICA:/opt/minecraft30/backups ./backups-minecraft
```
2. Con el último backup puedes levantar el mismo mundo en otro sitio (Oracle, una PC de casa, la renovación del año siguiente) con `./scripts/restore.sh` ([MANUAL §9.12](MANUAL.md#912-mover-el-servidor-a-otra-máquina)).

## 10. Solución de problemas

| Problema | Solución |
|---|---|
| **Todos** los tamaños salen *NotAvailableForSubscription* | Servicios sin registrar (§3.2) o región no permitida (§3.1) |
| No aparece `B2pls_v2` en la lista | Marca **Arm64** antes de elegir tamaño (§4) |
| `ssh` dice *UNPROTECTED PRIVATE KEY FILE* | Ejecuta el `icacls` de §6.1 |
| `./scripts/...: No such file or directory` | No estás en `/opt/minecraft30`: `cd /opt/minecraft30` (o §6.2, `.bashrc`) |
| Al instalar: *"El nick 'X' no existe"* | Usa el nick de Java (junto a "Jugar" en el launcher), no el de la cuenta de Microsoft |
| *Not available for subscription* al elegir el tamaño | Prueba otra región de tu lista (§3) o `Standard_B2als_v2` (imagen x64) |
| *RequestDisallowedByPolicy* al crear | La región no está permitida para tu suscripción (§3) |
| El servidor se reinicia solo y el log dice `OOMKilled` o `exit code 137` | `MC_MEMORY` demasiado alto para 4 GB: usa `2304M` / `3300m` |
| Nadie puede entrar (*timed out*) | Faltan las reglas del NSG (§5) o `sudo ufw status` no muestra 25565 |
| Lag tras muchas horas de juego seguidas | Créditos de CPU agotados (§1): baja `VIEW_DISTANCE` a 7 o espera a que se recuperen |
