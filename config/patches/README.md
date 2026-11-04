# Parches de configuración

La imagen `itzg/minecraft-server` aplica estos archivos JSON **en cada arranque**,
modificando solo las claves indicadas de los YAML que genera Paper. Así la
configuración queda versionada en git sin sobrescribir el archivo completo.

- `geyser.json`: Bedrock acepta los dos métodos de conexión (RakNet clásico en
  UDP 19132 y NetherNet nuevo: señalización TCP 19132 + UDP 19133) y los
  jugadores de Bedrock se autentican con Floodgate (cuenta de Xbox/Microsoft).
- `bukkit.json`: desactiva el límite de Paper de "una conexión cada 4 s por IP".
  Con él, una clase conectada desde la misma red (misma IP pública por NAT)
  o desde un túnel (playit) no podría entrar a la vez. La protección contra
  ataques la hace el firewall (`scripts/firewall.sh`: límites por IP).
- `paper-world-defaults.json`: activa **anti-xray** (oculta minerales a clientes
  tramposos) y limita entidades por chunk para reducir lag.

> En la **primera** ejecución Paper aún no ha creado los YAML, así que los
> parches se aplican a partir del **segundo** arranque. `scripts/install.sh`
> ya hace ese reinicio automáticamente.

Formato: https://docker-minecraft-server.readthedocs.io/en/latest/configuration/interpolating/#patching-existing-files
