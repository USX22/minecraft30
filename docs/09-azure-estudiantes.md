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

Precios reales de la API de Azure (noviembre de 2026, Linux, pago por uso). Al mes (730 h) se suman ~5 $ de disco y ~3,65 $ de IP pública:

| Tamaño | CPU | RAM | $/hora (East US 2) | ≈ $/mes total | Con 100 $ dura |
|---|---|---|---|---|---|
| **Standard_B2pls_v2** (recomendada) | 2 vCPU ARM (Ampere) | 4 GB | 0,0336 | **~33 $** | **~3 meses** |
| Standard_B2als_v2 (si la ARM no está disponible) | 2 vCPU AMD | 4 GB | 0,041–0,047 | ~40 $ | ~2,5 meses |
| Standard_B2ps_v2 | 2 vCPU ARM | 8 GB | 0,0672 | ~58 $ | ~1,7 meses |

El precio cambia según la región (East US 2 suele ser de las más baratas). Puedes comprobarlo en <https://azure.microsoft.com/pricing/calculator/>.

**¿Alcanzan 4 GB para 30 jugadores?** Sí, lo medimos: con la configuración de 4 GB (`MC_MEMORY=2304M`, `CONTAINER_MEM_LIMIT=3300m`) y 2 núcleos, **36 jugadores (bots) se mantuvieron a 20 TPS** durante la prueba y la memoria estable en 2,9 GB ([RESULTADOS-PRUEBAS.md](RESULTADOS-PRUEBAS.md)). Con 2,75 GB de *heap* el sistema mató el proceso por falta de memoria: Java necesita ~0,7–0,8 GB **además** del heap. No subas `MC_MEMORY` en una máquina de 4 GB.

**CPU con créditos (máquinas "B"):** la B2pls_v2 garantiza el 30 % de sus 2 núcleos y acumula créditos cuando usa menos (hasta 864). El servidor vacío usa ~6 % (acumula) y con 36 jugadores ~40 % (gasta ~12 créditos/hora): aguanta jornadas largas de juego sin frenarse. Puedes verlo en el portal: máquina → **Métricas** → *CPU Credits Remaining*.

## 2. Activar Azure for Students

1. Entra en <https://azure.microsoft.com/free/students>.
2. Pulsa **Start free** / **Activar ahora** e inicia sesión (o crea una cuenta de Microsoft) con tu **correo institucional**.
3. Verifica tu identidad (teléfono) y tu condición de estudiante (correo de la universidad). **No pide tarjeta.**
4. Al terminar tendrás una suscripción llamada **Azure for Students** con 100 $ de crédito. El saldo se ve en <https://portal.azure.com> → buscar **Education** → *Overview*.

> Microsoft da **una** oferta por estudiante. Si tienes dos correos institucionales, usa uno; el otro solo te sirve si el primero no se puede verificar.

## 3. Ver en qué regiones puedes crear máquinas

Las suscripciones de estudiante solo pueden usar **unas 5 regiones**, distintas para cada persona.
1. En el portal, busca **Policy** → **Assignments**.
2. Abre la asignación *Allowed resource deployment regions* → **Parameters**: ahí está tu lista.
3. Elige la más cercana a los jugadores (menos ping). Si está, *Mexico Central* o *South Central US* son buenas para Latinoamérica; *East US 2* suele ser la más barata.

## 4. Crear la máquina virtual

Necesitas tu llave SSH pública (Parte A del [TUTORIAL](TUTORIAL.md#parte-a--preparación-en-tu-computadora-10-min)).

Portal → **Virtual machines** → **Create** → **Azure virtual machine**:

**Pestaña Basics**

| Campo | Valor |
|---|---|
| Subscription | Azure for Students |
| Resource group | **Create new** → `minecraft30` |
| Virtual machine name | `minecraft30` |
| Region | Una de tus regiones permitidas (§3) |
| Availability options | No infrastructure redundancy required |
| Security type | Standard (o Trusted launch, cualquiera) |
| Image | **Ubuntu Server 24.04 LTS – Arm64** (para B2pls_v2). Si usas B2als_v2, la versión **x64** |
| Size | **See all sizes** → busca `B2pls_v2` → **Standard_B2pls_v2**. Si sale *Not available for subscription*, prueba `B2als_v2` (y cambia la imagen a x64) u otra región |
| Authentication type | **SSH public key** |
| Username | `azureuser` (o el que quieras) |
| SSH public key source | **Use existing public key** → pega la línea `ssh-ed25519 AAAA...` |
| Public inbound ports | **Allow selected ports** → **SSH (22)** |

**Pestaña Disks:** OS disk type → **Standard SSD** (más barato que Premium); tamaño **64 GiB**; marca *Delete with VM*.

**Pestaña Networking:** deja la red nueva y una **Public IP** nueva (Standard). NIC network security group: **Basic**, puertos públicos: SSH.

**Pestaña Management:** comprueba que **Auto-shutdown** esté **desactivado** (si no, el servidor se apagaría cada noche).

**Review + create** → **Create**. En 1–2 minutos la máquina está lista. En su página, copia la **Public IP address**: es tu `IP_PUBLICA`.

> Opcional: en la IP pública → **Configuration** → **Static**, para que no cambie si apagas la máquina.

## 5. Abrir los puertos del juego (para cualquier IP)

Máquina → **Networking** (o *Network settings*) → **Create port rule** → **Inbound port rule**. Crea estas 4 reglas (Source: **Any**, Action: **Allow**):

| Destination port ranges | Protocol | Name |
|---|---|---|
| 25565 | TCP | Minecraft-Java |
| 19132 | UDP | Bedrock-RakNet |
| 19132 | TCP | Bedrock-senalizacion |
| 19133 | UDP | Bedrock-NetherNet |

**No abras el 25575** (RCON).

## 6. Instalar el servidor

Igual que en Oracle, con el usuario de Azure. Desde tu computadora:

```bash
ssh azureuser@IP_PUBLICA
```

En la máquina:

```bash
sudo git clone https://github.com/usx22/minecraft30.git /opt/minecraft30 && sudo chown -R "$USER": /opt/minecraft30
```

```bash
cd /opt/minecraft30 && sudo ./scripts/bootstrap-host.sh
```

`bootstrap-host.sh` instala Docker, endurece SSH, configura el firewall (UFW) con los puertos de Java y Bedrock, fail2ban, 4 GB de swap y los servicios. Sal y vuelve a entrar:

```bash
exit
```

```bash
ssh azureuser@IP_PUBLICA
```

```bash
cd /opt/minecraft30 && ./scripts/install.sh
```

La primera vez crea `.env`. Edítalo:

```bash
nano .env
```

- `SERVER_OWNER=` y `WHITELIST=` → tu nick y los de tus compañeros.
- `TZ=` → tu zona horaria.
- **Memoria para la máquina de 4 GB (importante):**
  - `MC_MEMORY=2304M`
  - `CONTAINER_MEM_LIMIT=3300m`
- `MAX_PLAYERS=36` (lo que se midió con 4 GB; con la de 8 GB puedes dejar 40 y usar `MC_MEMORY=6G` / `CONTAINER_MEM_LIMIT=7g`).

Guarda (`Ctrl+O`, `Enter`, `Ctrl+X`) y ejecuta otra vez:

```bash
./scripts/install.sh
```

A partir de aquí todo es igual que en el [TUTORIAL](TUTORIAL.md) (partes D a L): primera conexión, roles, pruebas, pregeneración (en esta máquina el radio 3000 tarda ~2–3 h) y backups.

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
| *Not available for subscription* al elegir el tamaño | Prueba otra región de tu lista (§3) o `Standard_B2als_v2` (imagen x64) |
| *RequestDisallowedByPolicy* al crear | La región no está permitida para tu suscripción (§3) |
| El servidor se reinicia solo y el log dice `OOMKilled` o `exit code 137` | `MC_MEMORY` demasiado alto para 4 GB: usa `2304M` / `3300m` |
| Nadie puede entrar (*timed out*) | Faltan las reglas del NSG (§5) o `sudo ufw status` no muestra 25565 |
| Lag tras muchas horas de juego seguidas | Créditos de CPU agotados (§1): baja `VIEW_DISTANCE` a 7 o espera a que se recuperen |
