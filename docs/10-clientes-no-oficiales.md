# 10. Modo opcional: clientes de Minecraft no oficiales ("no premium")

Por defecto el servidor solo acepta **cuentas oficiales** de Minecraft Java (compradas) y de Bedrock (cuenta de Xbox/Microsoft). Este modo **opcional** permite entrar también con clientes Java **no oficiales** (sin cuenta comprada, como TLauncher u otros *launchers* "no premium").

> **Antes de activarlo, lee esto:**
> - **Legalidad:** jugar con un Minecraft no comprado va contra los términos de uso de Mojang/Microsoft. El servidor no lo impide en este modo, pero la responsabilidad es de cada jugador. Alternativa legal y barata: **Minecraft Bedrock** en el celular, que ya puede entrar al servidor (§4.7 del manual).
> - **Seguridad:** sin la verificación de Microsoft, **cualquiera puede elegir cualquier nombre**, incluido el tuyo. Por eso este modo instala **AuthMe**: cada jugador protege su nombre con una **contraseña**. El dueño y los admins deben registrarse **los primeros**.

---

## 1. Cómo funciona

| | Modo normal (por defecto) | Modo no premium |
|---|---|---|
| Quién verifica la identidad | Microsoft (`online-mode`) | El propio servidor, con **contraseña** (AuthMe) |
| Clientes Java | Solo oficiales | Oficiales **y** no oficiales |
| Bedrock | Sí (cuenta de Xbox) | Sí (igual que antes) |
| Al entrar | Juegas directamente | `/register` la primera vez; `/login` siempre (comandos en el chat) |
| Whitelist | Sí | **Sí** (sigue decidiendo quién entra) |
| Identificador del jugador (UUID) | El oficial de su cuenta | Uno calculado a partir del **nombre** |

**Por qué cambian los roles al activarlo:** el servidor guarda roles, OP, whitelist e inventarios por **UUID** (un identificador único), no por nombre. En el modo no premium el UUID de cada nombre es otro, así que para el servidor el "Gupyx" no premium es una persona distinta del "Gupyx" oficial. Por eso el script **rehace la whitelist, el OP del dueño y los roles**, y los jugadores **empiezan con inventario vacío** (el mundo y las construcciones no cambian). Al desactivar el modo, todo vuelve a los datos oficiales.

**AuthMe** (plugin de código abierto, [AuthMeReloaded](https://github.com/AuthMe/AuthMeReloaded)) mantiene "congelado" a quien entra: no puede moverse, hablar ni usar comandos hasta escribir su contraseña. Las contraseñas se guardan cifradas (*hash*), no en texto plano. El proyecto lo configura (`config/patches/authme.json`) para:
- **No limitar cuentas por IP** (por defecto solo dejaría 1 registro por IP, y toda una clase comparte la IP de la universidad).
- Permitir el punto en los nombres (jugadores de Bedrock: `.Gamertag`).
- Usar los comandos del chat en lugar de ventanas emergentes, que no funcionan en Bedrock ni en clientes antiguos.
- Mostrar los mensajes en el idioma del jugador (español por defecto).

## 2. Activar

En la VM, desde `/opt/minecraft30`:

```bash
./scripts/no-premium.sh activar
```

Pide confirmación (`si`), hace un backup, reinicia el servidor con AuthMe (2–4 minutos) y rehace whitelist, OP y roles.

**Inmediatamente después:**
1. **El dueño entra** (con cualquier cliente) y escribe en el chat: `/register TuClave TuClave`
2. Después de registrarse, en la VM: `./scripts/roles.sh setup` (el rol de Dueño se asigna a la cuenta no premium cuando ya ha entrado una vez).
3. Avisa a admins y moderadores para que entren y se registren cuanto antes, y vuelve a darles su rol (`./scripts/roles.sh mod Nick` / `admin Nick`) una vez hayan entrado.

Comprobar el modo actual:

```bash
./scripts/no-premium.sh estado
```

> **Si al entrar dice "no estás en la whitelist":** `./scripts/no-premium.sh arreglar-whitelist`. El servidor recuerda el identificador oficial de quien ya había entrado antes; el script escribe directamente el identificador correcto del modo no premium (lo mismo hace `whitelist.sh agregar` en este modo).

## 3. Para los jugadores

1. Pide a un admin que te añada a la whitelist (por tu **nick**, el que pones en tu launcher).
2. Entra al servidor (misma IP, puerto 25565).
3. **La primera vez:** escribe en el chat (tecla T): `/register MiClave MiClave` (mínimo 5 caracteres; no uses la contraseña de otras cuentas).
4. **Las siguientes veces:** `/login MiClave`
5. Cambiar la contraseña: `/changepassword ClaveVieja ClaveNueva`

Si escribes mal la contraseña, el servidor te expulsa; vuelve a entrar y repite.

## 4. Para los administradores

| Situación | Comando (consola de la VM o chat como admin) |
|---|---|
| Añadir jugador | `./scripts/whitelist.sh agregar Nick` |
| Un jugador olvidó su contraseña | `/authme unregister Nick` (podrá registrarse de nuevo) |
| Poner una contraseña a alguien | `/authme changepassword Nick NuevaClave` |
| Ver si alguien está registrado | `/authme accounts Nick` |
| Alguien registró el nombre de otra persona | `/authme unregister Nick`, y que el dueño real se registre enseguida |

## 5. Desactivar (volver a solo cuentas oficiales)

```bash
./scripts/no-premium.sh desactivar
```

Quita AuthMe, vuelve a la verificación de Microsoft y rehace whitelist y roles con los identificadores oficiales. Los jugadores con cuenta oficial recuperan su inventario y roles originales; los que solo tenían cliente no oficial ya no pueden entrar.

## 6. Cómo se probó

Con bots en el servidor de pruebas (`tests/load/authme-test.js`, **5/5**): pide registro al entrar, sin sesión no se puede hablar, `/register` crea la cuenta, con contraseña incorrecta expulsa y con la correcta inicia sesión. También se comprobó que `no-premium.sh desactivar` quita AuthMe y deja el servidor como estaba.

## 7. Conceptos para el informe

- **Autenticación delegada vs. local:** en modo normal la identidad la garantiza un tercero (Microsoft, con criptografía de clave pública); en modo no premium la garantiza el propio servidor con una contraseña (AuthMe), como un login web.
- **Identificadores:** el sistema se basa en UUID, no en nombres; cambiar el método de autenticación cambia los identificadores y, con ellos, los permisos asociados.
- **Hash de contraseñas:** AuthMe guarda un resumen criptográfico (*hash*), no la contraseña.
- **NAT y límites por IP:** por qué un límite de "1 registro por IP" bloquearía a toda una clase.
