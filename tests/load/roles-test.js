// Prueba automática de roles y moderación (Parte E del tutorial) con bots.
// SOLO contra un servidor en modo offline (servidor de prueba). Uso:
//   cd tests/load && npm install && node roles-test.js
// Usa ../../scripts/console.sh y roles.sh para preparar (whitelist y roles).
const mineflayer = require('mineflayer');
const { execSync } = require('child_process');
const { Vec3 } = require('vec3');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const HOST = process.env.HOST || '127.0.0.1';
const PORT = Number(process.env.PORT || 25565);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const clean = (s) => String(s).replace(/§./g, '').replace(/\x1b\[[0-9;]*m/g, '');

function rcon(cmd) {
  return clean(execSync(`${ROOT}/scripts/console.sh ${JSON.stringify(cmd)}`, { cwd: ROOT }).toString());
}
function roles(args) {
  return clean(execSync(`${ROOT}/scripts/roles.sh ${args}`, { cwd: ROOT }).toString());
}

const results = [];
function check(id, name, ok, detail = '') {
  results.push({ id, name, ok, detail });
  console.log(`${ok ? '✅' : '❌'} ${id} ${name}${detail ? ' — ' + detail : ''}`);
}

function join(username) {
  return new Promise((resolve, reject) => {
    const bot = mineflayer.createBot({ host: HOST, port: PORT, username, auth: 'offline' });
    bot.msgs = [];
    bot.kickReason = null;
    bot.on('messagestr', (m) => bot.msgs.push(clean(m)));
    bot.on('kicked', (r) => { bot.kickReason = clean(typeof r === 'string' ? r : JSON.stringify(r)); });
    bot.on('error', () => {});
    bot.once('spawn', () => resolve(bot));
    bot.once('end', () => reject(new Error(`${username} desconectado: ${bot.kickReason}`)));
    setTimeout(() => reject(new Error(`${username}: tiempo de espera agotado`)), 30000);
  });
}

// Espera un mensaje de chat que cumpla la regex (solo mensajes nuevos)
async function waitMsg(bot, re, ms = 5000) {
  const start = bot.msgs.length;
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    const hit = bot.msgs.slice(start).find((m) => re.test(m));
    if (hit) return hit;
    await sleep(200);
  }
  return null;
}
async function cmd(bot, text, re, ms) {
  const p = waitMsg(bot, re, ms);
  bot.chat(text);
  return p;
}
function waitEnd(bot, ms = 8000) {
  return new Promise((resolve) => {
    const t = setTimeout(() => resolve(false), ms);
    bot.once('end', () => { clearTimeout(t); resolve(true); });
  });
}

(async () => {
  const P = 'Jugador_Test', M = 'Mod_Test', A = 'Admin_Test';
  rcon(`whitelist add ${P}`); rcon(`whitelist add ${M}`); rcon(`whitelist add ${A}`);

  let jug = await join(P);
  const mod = await join(M);
  const adm = await join(A);
  check('D1', 'Bots (cliente 26.1) entran al servidor (ViaVersion)', true, `${P}, ${M}, ${A}`);

  // E2: un jugador normal no puede moderar
  let r = await cmd(jug, `/kick ${M} prueba`, /(permission|access|unknown|incomplete)/i);
  check('E2', 'Jugador normal no puede usar /kick', !!r, r || 'sin respuesta de denegación');

  // E3: roles
  roles(`mod ${M}`); roles(`admin ${A}`);
  await sleep(1500);
  const modInfo = roles(`info ${M}`), admInfo = roles(`info ${A}`);
  check('E3', 'Asignación de roles (moderador y admin)',
    /Primary Group: moderador/i.test(modInfo) && /Primary Group: admin/i.test(admInfo));

  // Prefijo en el chat (LPC): se comprueba en el log del servidor
  mod.chat('hola soy moderador');
  await sleep(1500);
  const log = clean(execSync(`grep "hola soy moderador" ${ROOT}/data/logs/latest.log | tail -1`).toString());
  check('E3b', 'Prefijo [Mod] visible en el chat', /\[Mod\].*Mod_Test/.test(log), log.trim());

  // E4: mute
  r = await cmd(mod, `/mute ${P} 1m prueba`, /muted/i);
  const mutedMsg = waitMsg(jug, /(silenced|muted)/i, 5000);
  jug.chat('esto no deberia verse');
  const r2 = await mutedMsg;
  check('E4a', 'Moderador silencia (/mute) y el jugador no puede hablar', !!r && !!r2, r2 || '');
  await cmd(mod, `/mute ${P}`, /unmuted/i); // quitar mute

  // E5: griefing + CoreProtect rollback
  rcon('fill 195 120 195 205 120 205 minecraft:stone');
  rcon('fill 201 121 200 203 121 200 minecraft:dirt');
  rcon(`tp ${P} 200 121 200`);
  await sleep(2000);
  await jug.waitForChunksToLoad();
  await sleep(1000);
  let dug = 0;
  for (const x of [201, 202, 203]) {
    const b = jug.blockAt(new Vec3(x, 121, 200));
    if (b && b.name === 'dirt') { try { await jug.dig(b, true); dug++; } catch (e) { /* ignorar */ } }
  }
  const broken = /passed/i.test(rcon('execute if block 202 121 200 minecraft:air'));
  await sleep(3000); // CoreProtect guarda en lote
  await cmd(mod, `/tp ${P}`, /.*/, 3000);
  await sleep(2000);
  r = await cmd(mod, `/co rollback u:${P} t:10m r:20`, /(rollback|completed|complet)/i, 15000);
  await sleep(3000);
  const restored = /passed/i.test(rcon('execute if block 202 121 200 minecraft:dirt'));
  check('E5', 'Griefing registrado y revertido con CoreProtect', dug > 0 && broken && restored,
    `bloques rotos=${dug}, revertido=${restored}`);

  // Inmunidad: el moderador no puede sancionar a un admin
  r = await cmd(mod, `/mute ${A} 1m prueba`, /(exempt|cannot|can't|may not|not allowed|no puedes)/i);
  check('E5b', 'Moderador NO puede sancionar a un admin (inmunidad)', !!r, r || '');

  // E4b: kick
  const ended = waitEnd(jug);
  mod.chat(`/kick ${P} prueba de kick`);
  check('E4b', 'Moderador expulsa (/kick) con motivo', (await ended) && /prueba de kick/i.test(jug.kickReason || ''), jug.kickReason || '');

  // E4c: tempban + unban
  jug = await join(P);
  const ended2 = waitEnd(jug);
  mod.chat(`/tempban ${P} 2m prueba de ban`);
  await ended2;
  let rejected = false;
  try { const j = await join(P); j.quit(); } catch (e) { rejected = /ban/i.test(e.message); }
  check('E4c', 'Moderador banea temporalmente (/tempban) y no puede volver a entrar', rejected);
  await cmd(mod, `/unban ${P}`, /.*/, 3000);
  await sleep(1000);
  try { jug = await join(P); check('E4d', 'Moderador quita el ban (/unban) y puede volver', true); }
  catch (e) { check('E4d', 'Moderador quita el ban (/unban) y puede volver', false, e.message); }

  // E6: un admin no puede ascenderse a owner ni darse OP
  adm.chat(`/lp user ${A} parent set owner`);
  adm.chat(`/op ${A}`);
  await sleep(2500);
  const info = roles(`info ${A}`);
  const isOwner = !/Primary Group: admin/i.test(info);
  const ops = execSync(`cat ${ROOT}/data/ops.json 2>/dev/null || echo []`).toString();
  check('E6', 'Admin NO puede hacerse owner ni darse OP', !isOwner && !ops.includes(A),
    `owner=${isOwner}, op=${ops.includes(A)}`);

  // F2: cuenta fuera de la whitelist es rechazada
  let wlRejected = false;
  try { const x = await join('Intruso_Test'); x.quit(); } catch (e) { wlRejected = /whitelist/i.test(e.message); }
  check('F2', 'Cuenta fuera de la whitelist es rechazada', wlRejected);

  // Limpieza
  roles(`quitar ${M}`); roles(`quitar ${A}`);
  for (const b of [jug, mod, adm]) { try { b.quit(); } catch (e) { /* */ } }
  const failed = results.filter((x) => !x.ok).length;
  console.log(`\nResultado: ${results.length - failed}/${results.length} pruebas superadas`);
  await sleep(500);
  process.exit(failed ? 1 : 0);
})().catch((e) => { console.error('ERROR:', e.message); process.exit(2); });
