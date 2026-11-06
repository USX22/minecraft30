// Prueba del modo no premium (AuthMe) con bots. Requiere el servidor en modo
// no premium (./scripts/no-premium.sh activar) y el bot en la whitelist.
//   cd tests/load && npm install && node authme-test.js
// Comprueba: pide registro, /register funciona, /login con clave correcta
// funciona, con clave incorrecta expulsa, y sin login no se puede hablar.
const mineflayer = require('mineflayer');
const { execSync } = require('child_process');
const path = require('path');

const ROOT = path.resolve(__dirname, '../..');
const HOST = process.env.HOST || '127.0.0.1';
const NAME = process.env.BOT || 'Jugador_Test';
const PASS = 'ClaveDePrueba123';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const clean = (s) => String(s).replace(/§./g, '');
const results = [];
const check = (id, name, ok, detail = '') => {
  results.push(ok);
  console.log(`${ok ? '✅' : '❌'} ${id} ${name}${detail ? ' — ' + detail : ''}`);
};

function join() {
  return new Promise((resolve, reject) => {
    const bot = mineflayer.createBot({ host: HOST, username: NAME, auth: 'offline' });
    bot.msgs = [];
    bot.kickReason = null;
    bot.on('messagestr', (m) => bot.msgs.push(clean(m)));
    bot.on('kicked', (r) => { bot.kickReason = clean(typeof r === 'string' ? r : JSON.stringify(r)); });
    bot.on('error', () => {});
    bot.once('spawn', () => resolve(bot));
    bot.once('end', () => reject(new Error(`desconectado: ${bot.kickReason}`)));
    setTimeout(() => reject(new Error('tiempo agotado')), 30000);
  });
}
async function waitMsg(bot, re, ms = 6000) {
  const start = bot.msgs.length; const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    const hit = bot.msgs.slice(start).find((m) => re.test(m));
    if (hit) return hit;
    await sleep(200);
  }
  return null;
}
const ended = (bot, ms = 10000) => new Promise((res) => {
  const t = setTimeout(() => res(false), ms); bot.once('end', () => { clearTimeout(t); res(true); });
});

(async () => {
  // Empezar limpio: borrar el registro previo del bot (si existe)
  execSync(`${ROOT}/scripts/console.sh "authme unregister ${NAME}"`, { cwd: ROOT, stdio: 'ignore' });

  let bot = await join();
  let r = await waitMsg(bot, /(register|registr)/i);
  check('N1', 'Al entrar sin cuenta, pide registrarse', !!r, r || '');

  const chatProbe = waitMsg(bot, /no deberia verse/i, 3000);
  bot.chat('esto no deberia verse');
  check('N2', 'Sin iniciar sesión no puede hablar en el chat', !(await chatProbe));

  bot.chat(`/register ${PASS} ${PASS}`);
  r = await waitMsg(bot, /(registrad|success|correctamente|exitosamente|logged|sesi[oó]n)/i);
  check('N3', '/register crea la cuenta', !!r, r || '');
  bot.quit(); await sleep(3000);

  bot = await join();
  const kicked = ended(bot);
  await waitMsg(bot, /(login|iniciar|sesi[oó]n)/i);
  bot.chat('/login ClaveIncorrecta');
  check('N4', 'Con contraseña incorrecta lo expulsa', await kicked, bot.kickReason || '');
  await sleep(3000);

  bot = await join();
  await waitMsg(bot, /(login|iniciar|sesi[oó]n)/i);
  bot.chat(`/login ${PASS}`);
  r = await waitMsg(bot, /(success|logged|correctamente|exitosamente|iniciad)/i);
  check('N5', 'Con contraseña correcta inicia sesión', !!r, r || '');
  bot.quit();

  const ok = results.filter(Boolean).length;
  console.log(`\nResultado: ${ok}/${results.length} pruebas superadas`);
  await sleep(500);
  process.exit(ok === results.length ? 0 : 1);
})().catch((e) => { console.error('ERROR:', e.message); process.exit(2); });
