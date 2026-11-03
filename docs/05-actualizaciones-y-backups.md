# 5. Actualizaciones y backups

## Qué se actualiza y cómo

| Elemento | Mecanismo | Frecuencia |
|---|---|---|
| Paquetes de Ubuntu (seguridad) | `unattended-upgrades` | Diaria, automática |
| Paper (último *build* de la versión elegida) | La imagen lo descarga al arrancar | En cada reinicio |
| Plugins | `MODRINTH_PROJECTS`: se descarga la última versión compatible al arrancar | En cada reinicio |
| Imágenes Docker (Java, scripts) | `docker compose pull` en `scripts/update.sh` | Semanal |
| Configuración del proyecto | `git pull` en `scripts/update.sh` | Semanal |

### Actualización automática semanal
`systemd/minecraft-update.timer` ejecuta `scripts/update.sh` cada **lunes a las 05:00**:

1. Avisa en el chat a los 5 min, 1 min y 10 s.
2. Hace un backup.
3. `git pull` de la configuración y `docker compose pull`.
4. Recrea los contenedores (al arrancar se actualizan Paper y plugins).
5. Espera a que el servidor esté *healthy*; si no, termina con error (visible en `journalctl -u minecraft-update`).

Ver la próxima ejecución y el resultado de la última:

```bash
systemctl list-timers minecraft-update.timer
```

```bash
journalctl -u minecraft-update -n 50
```

Actualizar a mano en cualquier momento:

```bash
./scripts/update.sh
```

### Cambiar de versión de Minecraft
Por defecto `MC_VERSION=LATEST`. Para un servidor estable, **fija la versión** (p. ej. `MC_VERSION=1.21.4`) y súbela a propósito cuando los plugins sean compatibles:

1. Haz backup: `./scripts/backup-now.sh`
2. Cambia `MC_VERSION` en `.env`.
3. `./scripts/update.sh --ahora`

> Nunca bajes de versión un mundo ya abierto con una versión más nueva: restaura un backup anterior.

## Backups

El contenedor `mc-backup`:
- Hace un backup cada `BACKUP_INTERVAL` (6 h) en `backups/` como `.tar.zst` comprimido.
- Antes de copiar ejecuta `save-off` + `save-all` por RCON, así el mundo copiado es **consistente**; luego `save-on`.
- Borra los de más de `PRUNE_BACKUPS_DAYS` (7 días).
- Monta `data/` en **solo lectura**: un fallo del backup no puede dañar el mundo.
- Excluye lo que se puede volver a descargar (`.jar`, `libraries`, `versions`, logs).

Backup inmediato:

```bash
./scripts/backup-now.sh
```

### Restaurar

```bash
./scripts/restore.sh
```

```bash
./scripts/restore.sh backups/world-AAAAMMDD-HHMMSS.tar.zst
```

El mundo actual no se borra: se mueve a `data.antes-de-restaurar-<fecha>`.

> Para revertir *griefing* en una zona concreta usa CoreProtect (`/co rollback`), no un backup completo: así nadie pierde su progreso.

### Copia fuera de la VM (regla 3-2-1)

Los backups en la misma VM no sirven si se pierde la VM. Opciones gratuitas:

**a) Copiar a tu computadora** (lo más simple):

```bash
rsync -avz -e "ssh -i tu_llave" ubuntu@IP_PUBLICA:~/minecraft30/backups/ ./backups-minecraft/
```

**b) Automático a la nube con rclone** (Google Drive 15 GB gratis, o Oracle Object Storage 20 GB *Always Free*). En la VM:

```bash
sudo apt install -y rclone && rclone config
```

Crea un *remote* llamado `nube` y añade a `crontab -e`:

```
30 */12 * * * rclone copy ~/minecraft30/backups nube:minecraft-backups --max-age 13h
```
