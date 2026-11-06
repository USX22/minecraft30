# 3. Seguridad

Se aplica **defensa en profundidad**: varias capas independientes, de modo que si una falla, las demás siguen protegiendo.

## Capas

| # | Capa | Medida | Protege contra |
|---|---|---|---|
| 1 | Red de Oracle | *Security List*: solo 22, 25565 (Java) y 19132-19133 (Bedrock) | Escaneo y acceso a cualquier otro servicio |
| 2 | Firewall de la VM | iptables (Oracle) o UFW: solo 22, 25565 y 19132-19133; UFW limita intentos al 22 | Servicios expuestos por error |
| 3 | Anti-flood | Cadena `DOCKER-USER`: máx. 40 conexiones simultáneas y ~60 nuevas/min por IP (`scripts/firewall.sh`) | Bots, ataques de login masivo, agotamiento de conexiones |
| 4 | SSH | Solo llave pública, sin root, `MaxAuthTries 3` | Fuerza bruta de contraseñas |
| 5 | fail2ban | Bloquea 1 h la IP tras 5 fallos de SSH en 10 min | Fuerza bruta sostenida |
| 6 | Sistema | `unattended-upgrades` instala parches de seguridad solo; reinicio a las 05:30 si hace falta | Vulnerabilidades conocidas del SO |
| 7 | Contenedor | Usuario sin privilegios (UID 1000), `cap_drop: ALL`, `no-new-privileges`, límites de RAM y procesos | Que una vulnerabilidad del juego/plugin comprometa la VM |
| 8 | Autenticación de jugadores | `online-mode=true`: solo cuentas compradas, verificadas por Microsoft | Suplantación de identidad (alguien entrando como el admin) |
| 9 | Whitelist | `enforce-whitelist`: solo entran los nicks autorizados | Desconocidos, *griefers* |
| 10 | Chat firmado | `enforce-secure-profile` | Falsificación de mensajes |
| 11 | RCON | No publicado a internet; contraseña aleatoria de 32 caracteres; `.env` con permisos 600 y fuera de git | Control remoto del servidor por terceros |
| 12 | Permisos | LuckPerms con mínimo privilegio; solo el dueño tiene OP y gestiona roles | Escalada de privilegios de moderadores/admins |
| 13 | Anti-trampas | Anti-xray de Paper (oculta minerales) | Hack de x-ray |
| 14 | Auditoría y recuperación | CoreProtect registra cada bloque puesto/roto/cofre abierto; backups cada 6 h | *Griefing* y robos: se identifican y se revierten |
| 15 | Entrada de scripts | Los nicks se validan con `^[A-Za-z0-9_]{3,16}$` antes de mandarlos a la consola | Inyección de comandos |
| 16 | Integridad | El servicio de firewall (root) ejecuta una copia en `/usr/local/sbin` propiedad de root | Que un usuario normal modifique código que corre como root |

## Detalles importantes

### ¿Por qué el anti-flood va en `DOCKER-USER` y no en UFW?
Docker publica puertos insertando reglas NAT en la cadena `FORWARD`, que **se salta las reglas de UFW/INPUT**. La cadena `DOCKER-USER` es la que Docker reserva para reglas del administrador y se evalúa antes que las suyas.

### ¿Por qué 40 conexiones por IP y no 3?
En una clase, todos los alumnos conectados desde la red de la universidad salen a internet con **la misma IP pública** (NAT). Un límite bajo bloquearía a la clase entera.

### Contraseñas y secretos
- `.env` está en `.gitignore` y la CI falla si alguien lo sube.
- `install.sh` genera la contraseña RCON con `openssl rand`.
- Nunca compartas `.env` ni la llave privada SSH.

### DDoS a gran escala
Las reglas anti-flood frenan abusos de una IP, pero no un DDoS distribuido de gran volumen. Para un servidor de clase el riesgo es bajo (la IP no se publica en listas). Si fuera necesario, se puede poner delante un proxy con protección (p. ej. TCPShield, que tiene plan gratuito) — ver [docs/07](07-alternativas-y-costos.md).

## Lista de verificación

```bash
sudo ss -tlnp
```
Solo deben escucharse públicamente el 22, el 25565 y el 19132 (TCP); con `sudo ss -ulnp`, el 19132 y 19133 (UDP). El 25575 **no** debe aparecer.

> Los jugadores de Bedrock se autentican con su cuenta de Xbox/Microsoft a través de Floodgate, que firma sus datos con una llave privada propia (`data/plugins/floodgate/key.pem`, generada automáticamente; no la compartas). La whitelist y los roles se aplican igual que en Java.

```bash
sudo iptables -L MC-PROTECT -n -v
```

```bash
sudo fail2ban-client status sshd
```

```bash
docker inspect mc --format 'Usuario: {{.Config.User}}  Caps eliminadas: {{.HostConfig.CapDrop}}'
```
