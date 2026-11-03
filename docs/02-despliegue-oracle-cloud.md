# 2. Despliegue en Oracle Cloud (gratis) — paso a paso

> **Nota sobre los límites gratuitos (2026):** la documentación oficial de Oracle
> indica 4 OCPU + 24 GB de RAM gratis para instancias Ampere A1, pero desde
> mediados de 2026 varios usuarios reportan que la cuota se redujo a ~2 OCPU +
> 12 GB. **Este proyecto está pensado para funcionar con 2 OCPU / 12 GB.** Revisa
> en tu consola (*Governance → Limits*) cuánto tienes y ajusta `MC_MEMORY`.

## 1. Crear la cuenta

1. Regístrate en <https://www.oracle.com/cloud/free/>. Piden tarjeta para verificar identidad, pero **no se cobra** si solo usas recursos *Always Free*.
2. Elige una *home region* cercana a los jugadores (menos latencia). No se puede cambiar después.
3. **Recomendado:** activa *Pay As You Go* (sigue costando 0 $ si no sales de los límites gratuitos). Así Oracle no recupera la VM por "inactiva" y es más fácil conseguir capacidad ARM. Pon una alerta de presupuesto de 1 $ en *Billing → Budgets* por seguridad.

## 2. Crear la VM

*Compute → Instances → Create instance*:

| Campo | Valor |
|---|---|
| Image | **Canonical Ubuntu 24.04** (o 22.04) |
| Shape | **VM.Standard.A1.Flex** (Ampere, ARM) |
| OCPU / Memoria | El máximo gratuito disponible (2 OCPU/12 GB o 4 OCPU/24 GB) |
| Networking | Crear VCN nueva con subred **pública** y **asignar IP pública** |
| SSH keys | Sube tu llave pública (o genera una y **descarga la privada**) |
| Boot volume | 100 GB (el límite gratuito total es 200 GB) |

> Si sale *"Out of capacity"*, prueba otro *Availability Domain* o vuelve a intentarlo más tarde; con cuenta *Pay As You Go* es mucho menos frecuente.

Anota la **IP pública**.

## 3. Abrir el puerto en la red de Oracle

*Networking → Virtual Cloud Networks → (tu VCN) → Security Lists → Default Security List → Add Ingress Rules*:

| Source CIDR | Protocol | Destination port | Descripción |
|---|---|---|---|
| `0.0.0.0/0` | TCP | `25565` | Minecraft |

El puerto 22 (SSH) ya viene abierto. Para más seguridad puedes restringir el origen del 22 a tu IP.

**No abras el 25575 (RCON)**: solo se usa dentro de la VM.

## 4. Preparar la VM

Desde tu computadora:

```bash
ssh -i ruta/a/tu_llave ubuntu@IP_PUBLICA
```

Ya dentro de la VM:

```bash
git clone https://github.com/usx22/minecraft30.git ~/minecraft30
```

```bash
cd ~/minecraft30 && sudo ./scripts/bootstrap-host.sh
```

El script instala Docker, endurece SSH, configura el firewall (detecta la imagen de Oracle y usa sus reglas iptables), fail2ban, swap y los servicios systemd. Tarda unos minutos.

Sal (`exit`) y vuelve a entrar por SSH para que tu usuario quede en el grupo `docker`.

## 5. Configurar e instalar el servidor

```bash
cd ~/minecraft30 && ./scripts/install.sh
```

La primera vez solo crea `.env`. Edítalo:

```bash
nano .env
```

- `SERVER_OWNER`: tu nick exacto de Minecraft.
- `WHITELIST`: los nicks iniciales separados por coma (luego usa `whitelist.sh`).
- `MC_MEMORY` / `CONTAINER_MEM_LIMIT`: `8G`/`10g` con 12 GB de RAM; `12G`/`14g` con 24 GB.
- `TZ`: tu zona horaria (ej. `America/Bogota`, `America/Lima`, `Europe/Madrid`).

Ejecuta de nuevo:

```bash
./scripts/install.sh
```

Descarga Paper y los plugins, arranca, aplica los parches de configuración y crea los roles. Cuando diga *"¡Servidor listo!"* conéctate desde Minecraft a `IP_PUBLICA`.

## 6. Pregenerar el mundo (muy recomendado)

Generar terreno nuevo es lo que más CPU consume. Hazlo antes de abrir el servidor:

```bash
./scripts/console.sh "chunky radius 3000"
```

```bash
./scripts/console.sh "chunky start"
```

Con 2 OCPU tarda unas horas; puedes ver el progreso con `./scripts/console.sh "chunky progress"`. Después pon un borde de mundo para que no se genere más terreno:

```bash
./scripts/console.sh "worldborder set 6000"
```

## 7. (Opcional) Un nombre en vez de la IP

1. Entra en <https://www.duckdns.org> (gratis), crea un subdominio (ej. `misala.duckdns.org`) y apúntalo a la IP pública.
2. Los jugadores se conectan a `misala.duckdns.org`.

La IP pública de Oracle no cambia mientras no borres la VM. Si quieres asegurarlo, conviértela en *Reserved Public IP* (también gratis, 1 por cuenta).

## 8. Verificar

```bash
./scripts/status.sh
```

```bash
systemctl list-timers minecraft-update.timer
```

Prueba de reinicio completo (el servidor debe volver solo):

```bash
sudo reboot
```

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| "Connection timed out" desde Minecraft | Falta la regla de la *Security List* (paso 3) o el puerto en iptables (`sudo iptables -L INPUT -n`). |
| "You are not whitelisted" | `./scripts/whitelist.sh agregar Nick` |
| El contenedor se reinicia en bucle | `docker compose logs mc`. Suele ser falta de RAM: baja `MC_MEMORY`. |
| `permission denied` en `data/` | `sudo chown -R 1000:1000 data backups` |
| Oracle borró/paró la VM | Instancia considerada inactiva. Activa *Pay As You Go* (paso 1.3). |
