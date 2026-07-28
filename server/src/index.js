// Entry point server Hestia.
import config from './config.js';
import { initDb } from './db/index.js';
import { createApp } from './app.js';
import { getStorageStatus, ensureStorageLayout } from './storage/manager.js';

function main() {
  // 1. Inisialisasi database metadata.
  initDb();
  console.log(`[db]      SQLite siap di ${config.dbPath}`);

  // 2. Cek storage HDD (informatif — server tetap jalan walau HDD belum ada).
  const status = getStorageStatus();
  if (status.available) {
    ensureStorageLayout();
    console.log(`[storage] Tersedia di ${status.path}`);
  } else {
    console.warn(`[storage] TIDAK tersedia (${status.reason}) di ${status.path} — upload akan ditolak sampai HDD siap.`);
  }

  // 3. Mulai HTTP server.
  const app = createApp();
  app.listen(config.port, () => {
    console.log(`[server]  Hestia berjalan di http://localhost:${config.port} (env: ${config.env})`);
  });
}

main();
