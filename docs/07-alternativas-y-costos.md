# 7. Alternativas y costos

> Precios aproximados a noviembre de 2026; cambian con frecuencia, verifícalos antes de decidir.

## Comparación

| Opción | Costo mensual | ¿30 jugadores? | 24/7 | Control total | Comentario |
|---|---|---|---|---|---|
| **Oracle Cloud Always Free (ARM)** — *elegida* | **0 $** | Sí (2 OCPU/12 GB) | Sí | Sí | Requiere tarjeta para verificar. Puede costar conseguir capacidad ARM. Riesgo de recuperación por inactividad si la cuenta es solo *Free*. |
| **Raspberry Pi 4/5 (8 GB) + [playit.gg](https://playit.gg)** — *alternativa sin tarjeta* | **0 $** (+ ~5 W de luz) | ~10–15 (hasta ~20 con mundo pregenerado) | Sí | Sí | No pide tarjeta ni cuenta en la nube. Túnel sin abrir puertos. Guía completa: **[docs/08](08-raspberry-pi.md)**. |
| PC propia/vieja + [playit.gg](https://playit.gg) | 0 $ (+ electricidad) | Depende del hardware (≥ 4 núcleos, 8 GB) | Si la dejas encendida | Sí | Sin abrir puertos del router (túnel). Añade algo de latencia. Ideal como respaldo o para pruebas. |
| PC propia + port forwarding | 0 $ | Igual que arriba | Igual | Sí | Necesita IP pública (muchas redes residenciales usan CG-NAT y no lo permiten) y expone tu IP de casa. |
| VPS barato ARM (p. ej. Hetzner CAX21: 4 vCPU / 8 GB) | ~7–9 € | Sí | Sí | Sí | La opción de pago más rentable. El mismo repositorio funciona sin cambios. |
| VPS x86 económico (Contabo, OVH, etc. 4 vCPU / 8 GB) | ~6–12 $ | Sí | Sí | Sí | CPU compartida: rendimiento más variable. |
| Aternos / Minehut (gratis) | 0 $ | Limitado | **No**: se apaga sin jugadores, colas de espera | No (sin SSH ni Docker) | No cumple los requisitos de continuidad ni sirve para el curso (no hay SO que administrar). |
| Hosting de Minecraft de pago | 5–15 $ | Sí | Sí | Parcial (panel) | Cómodo pero no se aprende SO/Redes. |

### Por qué Oracle Cloud
Es la **única opción gratuita** que da una VM completa (con SSH, root, firewall propio y sistema operativo a administrar), siempre encendida y con suficiente RAM para 30 jugadores. Además, permite aplicar todos los temas del curso.

### Costos de este proyecto con Oracle

| Recurso | Uso | Límite gratuito | Costo |
|---|---|---|---|
| VM A1.Flex | 2–4 OCPU, 12–24 GB | Según cuota *Always Free* de la cuenta | 0 $ |
| Disco | 100 GB | 200 GB | 0 $ |
| Tráfico de salida | ~0,5–1 TB/mes con 30 jugadores activos | 10 TB/mes | 0 $ |
| IP pública reservada | 1 | 1 | 0 $ |
| Dominio | DuckDNS | Gratis | 0 $ |
| **Total** | | | **0 $** |

Configura una alerta de presupuesto (*Billing → Budgets*, 1 $) para enterarte si algo deja de ser gratis.

## Migrar a otra máquina

Como todo está en Docker y en git, mover el servidor es:

1. En la máquina vieja: `./scripts/backup-now.sh` y copia el último archivo de `backups/` y tu `.env`.
2. En la nueva: `git clone`, `sudo ./scripts/bootstrap-host.sh`, coloca `.env`, copia el backup a `backups/`.
3. `./scripts/restore.sh backups/ARCHIVO` y luego `./scripts/roles.sh setup` (los roles ya vienen en el backup, pero no hace daño).

## Usar playit.gg con este repositorio (sin IP pública)

El repositorio ya trae el agente de playit en `docker-compose.raspberrypi.yml` (además limita la CPU para dejar un núcleo libre). Sirve para una Raspberry Pi o cualquier PC de casa con Linux de 64 bits:

1. Copia `.env.raspberrypi.example` a `.env` (en una Pi, `install.sh` lo hace solo). Contiene `COMPOSE_FILE=docker-compose.yml:docker-compose.raspberrypi.yml`.
2. Pon la clave del agente en `PLAYIT_SECRET_KEY`.
3. Crea un túnel "Minecraft Java" en la web de playit apuntando a `127.0.0.1:25565`.

Paso a paso completo en [docs/08](08-raspberry-pi.md). En una PC que no es Raspberry Pi, ejecuta `bootstrap-host.sh` e `install.sh` con `PERFIL=raspberrypi` delante para usar los mismos ajustes de "servidor en casa".

## Protección DDoS (opcional)
[TCPShield](https://tcpshield.com) tiene un plan gratuito que oculta la IP real del servidor detrás de su red. Requiere un dominio propio y configurar el proxy; no es necesario para un servidor de clase.
