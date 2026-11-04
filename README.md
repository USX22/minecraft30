# Servidor de Minecraft para 30+ jugadores — gratis, seguro y continuo

Proyecto de **Sistemas Operativos y Redes**: un servidor de Minecraft Java que

> 🚀 **[TUTORIAL PASO A PASO](docs/TUTORIAL.md)**: una sola lista de pasos, para cualquier persona, desde cero hasta el servidor instalado y **probado** (con tabla de resultados para el informe).
>
> 📘 **[MANUAL COMPLETO](docs/MANUAL.md)**: instalación desde cero, conceptos técnicos explicados y guías para jugadores, moderadores, admins, dueño y administradores de sistema.

| Requisito | Cómo se cumple |
|---|---|
| **30+ jugadores** | Paper (servidor optimizado), JVM afinada (flags de Aikar), mundo pregenerado. Medido en prueba con 2 núcleos: **90 jugadores (bots) con TPS 20**. Estimación prudente para jugadores reales: **~50–70** con 2 OCPU/12 GB y **~100** con 4 OCPU/24 GB ([MANUAL §3](docs/MANUAL.md#3-cuántos-jugadores-soporta)). Se verifica con una [prueba de carga con bots](docs/06-rendimiento.md) · [resultados](docs/RESULTADOS-PRUEBAS.md). |
| **Minecraft Java oficial** | Los jugadores usan el cliente **oficial** sin instalar nada; se exigen cuentas oficiales. ViaVersion/ViaBackwards permiten entrar aunque su versión no coincida exactamente. Opcional: el **servidor oficial** de Mojang (vanilla) con una línea en `.env` ([MANUAL §12](docs/MANUAL.md#12-modo-vanilla-servidor-oficial-de-mojang)). |
| **Bedrock (móvil, Windows, consolas)** | Geyser + Floodgate: los jugadores de Bedrock entran con su cuenta de Xbox/Microsoft, sin comprar Java, al **mismo mundo** ([MANUAL §4.7](docs/MANUAL.md#47-entrar-desde-minecraft-bedrock-móvil-windows-consolas)). |
| **Acceso desde cualquier IP** | Puerto 25565 abierto a `0.0.0.0/0`: se entra desde casa, la universidad o datos móviles. Quién entra lo decide la whitelist (por nick), no la IP. Puerto 443 opcional para redes restrictivas ([MANUAL §9.13](docs/MANUAL.md#913-puerto-alternativo-para-redes-que-bloquean-el-25565)). |
| **Funcionamiento continuo** | Docker con `restart: unless-stopped`, *healthcheck*, servicio `systemd` que lo levanta al arrancar la VM. |
| **Gratis o lo más barato posible** | VM *Always Free* de Oracle Cloud (0 $/mes). Alternativas en [docs/07](docs/07-alternativas-y-costos.md). |
| **Seguro** | Whitelist, cuentas oficiales (`online-mode`), contenedor sin root, firewall + anti-flood, SSH solo con llave, fail2ban, anti-xray, RCON no expuesto. Ver [docs/03](docs/03-seguridad.md). |
| **Administradores y moderadores** | LuckPerms con jerarquía `jugador < moderador < admin < dueño`, más EssentialsX (ban/mute/kick) y CoreProtect (deshacer *griefing*). Varios **administradores de sistema** con acceso SSH propio (`scripts/sysadmins.sh`). Ver [docs/04](docs/04-administracion.md). |
| **Actualizable** | Actualización semanal automática con aviso a jugadores y backup previo; Paper y plugins se actualizan solos. Ver [docs/05](docs/05-actualizaciones-y-backups.md). |
| **Backups** | Cada 6 h, comprimidos, 7 días de retención, restauración con un comando. |

## Arquitectura

```
                Internet
                   │  TCP 25565 (único puerto de juego abierto)
                   ▼
 ┌─────────── VM Ubuntu (Oracle Cloud Always Free, ARM) ────────────┐
 │  Firewall: Security List de Oracle + iptables/UFW + anti-flood   │
 │  SSH (22) solo con llave + fail2ban                              │
 │                                                                  │
 │  Docker ─────────────────────────────────────────────────────┐   │
 │  │  ┌──────────────────────┐   RCON 25575    ┌─────────────┐ │   │
 │  │  │ mc  (Paper + plugins)│◄──(red interna)─│ mc-backup   │ │   │
 │  │  │ usuario 1000, sin    │                 │ cada 6 h    │ │   │
 │  │  │ capabilities         │                 └──────┬──────┘ │   │
 │  │  └─────────┬────────────┘                        │        │   │
 │  └────────────┼─────────────────────────────────────┼────────┘   │
 │          ./data (mundo)                    ./backups (.tar.zst)  │
 │                                                                  │
 │  systemd: minecraft.service · minecraft-firewall.service ·       │
 │           minecraft-update.timer (lunes 05:00)                   │
 └──────────────────────────────────────────────────────────────────┘
```

Más detalle y relación con los temas del curso en [docs/01-arquitectura.md](docs/01-arquitectura.md).

## Inicio rápido

Guía completa paso a paso: **[docs/02-despliegue-oracle-cloud.md](docs/02-despliegue-oracle-cloud.md)**.

En una VM Ubuntu 22.04/24.04 recién creada:

```bash
sudo git clone https://github.com/usx22/minecraft30.git /opt/minecraft30 && sudo chown -R "$USER": /opt/minecraft30
```

```bash
cd /opt/minecraft30 && sudo ./scripts/bootstrap-host.sh
```

Cierra la sesión SSH, vuelve a entrar y:

```bash
cd /opt/minecraft30 && ./scripts/install.sh
```

La primera ejecución crea `.env`: edítalo (tu nick en `SERVER_OWNER`, la whitelist, la memoria) y ejecuta `./scripts/install.sh` otra vez. Al terminar, conéctate a `IP-PÚBLICA:25565`.

## Comandos del día a día

| Tarea | Comando |
|---|---|
| Ver estado (jugadores, TPS, RAM, backups) | `./scripts/status.sh` |
| Añadir jugadores a la whitelist | `./scripts/whitelist.sh agregar Nick1 Nick2` |
| Hacer moderador / admin | `./scripts/roles.sh mod Nick` · `./scripts/roles.sh admin Nick` |
| Quitar rol | `./scripts/roles.sh quitar Nick` |
| Añadir administrador de sistema | `sudo ./scripts/sysadmins.sh agregar usuario "ssh-ed25519 AAAA..."` |
| Consola del servidor | `./scripts/console.sh` o `./scripts/console.sh "say Hola"` |
| Backup inmediato | `./scripts/backup-now.sh` |
| Restaurar backup | `./scripts/restore.sh` (lista) · `./scripts/restore.sh backups/ARCHIVO` |
| Actualizar ahora | `./scripts/update.sh` (avisa 5 min antes) |
| Ver logs | `docker compose logs -f mc` |

## Estructura del repositorio

```
docker-compose.yml        Servicios: servidor (mc) y backups (mc-backup)
docker-compose.vanilla.yml Modo opcional con el servidor oficial de Mojang
.env.example              Plantilla de configuración (el .env real NO va a git)
config/patches/           Ajustes de Paper versionados (anti-xray, límites de entidades)
scripts/
  bootstrap-host.sh       Prepara y asegura la VM (Docker, firewall, SSH, fail2ban, swap, systemd)
  install.sh              Primera instalación del servidor
  roles.sh                Roles con LuckPerms (admin, moderador)
  whitelist.sh            Gestión de la whitelist
  console.sh              Consola RCON
  status.sh               Estado y métricas
  backup-now.sh/restore.sh Backups
  update.sh               Actualización segura
  firewall.sh             Reglas anti-flood (iptables DOCKER-USER)
  sysadmins.sh            Alta/baja de administradores de sistema (SSH)
systemd/                  Servicios y timer de systemd
tests/load/               Prueba de carga con 35 bots (mineflayer)
docs/                     Documentación detallada
.github/workflows/ci.yml  Validación automática (compose, shellcheck, secretos)
```

## Documentación

**[TUTORIAL PASO A PASO](docs/TUTORIAL.md)** (empieza aquí) · **[MANUAL COMPLETO](docs/MANUAL.md)** (referencia). Documentos temáticos:

1. [Arquitectura y conceptos de SO/Redes](docs/01-arquitectura.md)
2. [Despliegue en Oracle Cloud (paso a paso)](docs/02-despliegue-oracle-cloud.md)
3. [Seguridad](docs/03-seguridad.md)
4. [Administración: roles, moderación y comandos](docs/04-administracion.md)
5. [Actualizaciones y backups](docs/05-actualizaciones-y-backups.md)
6. [Rendimiento y prueba de carga](docs/06-rendimiento.md)
7. [Alternativas y costos](docs/07-alternativas-y-costos.md)
