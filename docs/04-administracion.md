# 4. Administración: roles, moderación y comandos

> Versión resumida. La guía completa por rol está en el [MANUAL](MANUAL.md) (§5–§7 y §9).

## Jerarquía de roles

```
owner (Dueño)   ── todo, incluido gestionar roles. Solo SERVER_OWNER.
  └─ admin      ── todo excepto: gestionar roles (LuckPerms), dar/quitar OP
       └─ moderador ── kick, mute, tempban, jail, vanish, tp, inspeccionar y revertir griefing
            └─ default (jugador) ── home, tpa, msg, back, spawn, helpop
```

Cada rol **hereda** los permisos del de abajo. Se crean con `./scripts/roles.sh setup` (lo ejecuta `install.sh`; puedes repetirlo tras editar el script, es idempotente).

### Asignar roles (desde la VM)

```bash
./scripts/roles.sh mod NickDelModerador
```

```bash
./scripts/roles.sh admin NickDelAdmin
```

```bash
./scripts/roles.sh quitar Nick
```

```bash
./scripts/roles.sh info Nick
```

El dueño también puede hacerlo dentro del juego: `/lp user Nick parent set moderador`.

### ¿Por qué no usar `/op`?
OP de vanilla es "todo o nada": un moderador con OP puede darse creativo, borrar el mundo o dar OP a otros. Con LuckPerms cada rol tiene **solo lo que necesita** (principio de mínimo privilegio) y los admins no pueden ascenderse a sí mismos.

## Comandos para moderadores

| Situación | Comando |
|---|---|
| Expulsar | `/kick Nick motivo` |
| Silenciar 10 minutos | `/mute Nick 10m motivo` |
| Ban temporal 1 día | `/tempban Nick 1d motivo` |
| Quitar ban | `/unban Nick` |
| Encarcelar | `/jail Nick nombreCarcel 30m` (crear cárcel: admin con `/setjail nombre`) |
| Ir con un jugador / traerlo | `/tp Nick` · `/tphere Nick` |
| Modo invisible para vigilar | `/vanish` |
| Ver inventario | `/invsee Nick` |
| Modo espectador | `/gamemode spectator` |
| Ver información de un jugador | `/whois Nick` · `/seen Nick` |
| Añadir a whitelist | `/whitelist add Nick` |
| Anuncio a todos | `/broadcast mensaje` |
| Ver TPS / salud | `/tps` · `/spark healthreport` |

### Investigar y revertir griefing (CoreProtect)

| Acción | Comando |
|---|---|
| Activar inspector (clic en un bloque para ver quién lo tocó) | `/co i` |
| Ver lo que hizo un jugador en la última hora cerca de ti | `/co lookup u:Nick t:1h r:30` |
| **Deshacer** todo lo que rompió/puso un jugador en 2 h, radio 50 | `/co rollback u:Nick t:2h r:50` |
| Rehacer (si te equivocaste) | `/co restore u:Nick t:2h r:50` |

## Comandos solo de admin

| Acción | Comando |
|---|---|
| Ban permanente | `/ban Nick motivo` |
| Modo creativo | `/gamemode creative` |
| Crear cárcel | `/setjail nombre` |
| Fijar spawn | `/setspawn` |
| Recargar EssentialsX | `/essentials reload` |
| Apagar/reiniciar | `/stop` (Docker lo vuelve a levantar solo) |

## Comandos para jugadores

`/sethome`, `/home`, `/spawn`, `/tpa Nick`, `/tpaccept`, `/back`, `/msg Nick texto`, `/r texto`, `/mail send Nick texto`, `/helpop mensaje` (llega a los moderadores), `/afk`, `/rules`.

## Gestión desde la VM

| Tarea | Comando |
|---|---|
| Whitelist | `./scripts/whitelist.sh agregar Nick1 Nick2` · `quitar Nick` · `lista` |
| Consola interactiva | `./scripts/console.sh` (salir con Ctrl+C) |
| Comando suelto | `./scripts/console.sh "say Reinicio en 5 minutos"` |
| Estado | `./scripts/status.sh` |
| Logs en vivo | `docker compose logs -f mc` |

## Personalizar permisos

Edita las listas de `set_perms` en `scripts/roles.sh` y ejecuta `./scripts/roles.sh setup`, o usa LuckPerms directamente:

```bash
./scripts/console.sh "lp group moderador permission set essentials.fly true"
```

LuckPerms también tiene un editor web: `./scripts/console.sh "lp editor"` devuelve un enlace temporal.

Reglas del servidor (las que ve `/rules`): edita `data/plugins/Essentials/rules.txt`.
