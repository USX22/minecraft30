// Prueba de carga: conecta N bots que caminan y saltan al azar.
// SOLO contra tu servidor de prueba (modo offline). Uso:
//   cd tests/load && npm install
//   BOTS=35 HOST=127.0.0.1 node bots.js
// Mientras corre, mide en otra terminal:  ./scripts/console.sh tps
const mineflayer = require('mineflayer');

const HOST = process.env.HOST || '127.0.0.1';
const PORT = Number(process.env.PORT || 25565);
const BOTS = Number(process.env.BOTS || 35);
const DELAY_MS = Number(process.env.DELAY_MS || 3000); // entre conexiones

let online = 0;

function spawnBot(i) {
  const bot = mineflayer.createBot({ host: HOST, port: PORT, username: `bot_${i}`, auth: 'offline' });

  bot.once('spawn', () => {
    online++;
    console.log(`[+] bot_${i} conectado (${online}/${BOTS})`);
    // Movimiento aleatorio para generar carga realista (chunks, entidades)
    setInterval(() => {
      bot.clearControlStates();
      const dirs = ['forward', 'back', 'left', 'right'];
      bot.setControlState(dirs[Math.floor(Math.random() * dirs.length)], true);
      bot.setControlState('jump', Math.random() < 0.3);
      bot.setControlState('sprint', Math.random() < 0.5);
      bot.look(Math.random() * Math.PI * 2, 0, true);
    }, 2000);
  });

  bot.on('kicked', (r) => console.log(`[!] bot_${i} expulsado:`, r));
  bot.on('error', (e) => console.log(`[!] bot_${i} error:`, e.message));
  bot.on('end', () => { online = Math.max(0, online - 1); console.log(`[-] bot_${i} desconectado`); });
}

for (let i = 1; i <= BOTS; i++) setTimeout(() => spawnBot(i), i * DELAY_MS);
