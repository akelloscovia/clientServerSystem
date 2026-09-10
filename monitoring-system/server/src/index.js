import { createApp } from './app.js';
import { config } from './config.js';
import { prisma } from './db.js';

const app = createApp();

const server = app.listen(config.port, config.host, () => {
  console.log(`monitoring-system API listening on http://${config.host}:${config.port} (${config.env})`);
});

async function shutdown(signal) {
  console.log(`\n${signal} received, shutting down…`);
  server.close();
  await prisma.$disconnect();
  process.exit(0);
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
