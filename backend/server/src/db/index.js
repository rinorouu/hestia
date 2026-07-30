// Koneksi & inisialisasi database SQLite (better-sqlite3, sinkron & ringan).
import Database from 'better-sqlite3';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import config from '../config.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let db;

// Membuka koneksi DB, membuat folder induk bila perlu, dan menerapkan skema.
export function initDb() {
  const dir = path.dirname(config.dbPath);
  fs.mkdirSync(dir, { recursive: true });

  db = new Database(config.dbPath);
  db.pragma('journal_mode = WAL');   // lebih tahan terhadap penulisan bersamaan
  db.pragma('foreign_keys = ON');

  const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  db.exec(schema);

  return db;
}

// Akses koneksi yang sudah diinisialisasi.
export function getDb() {
  if (!db) throw new Error('Database belum diinisialisasi. Panggil initDb() dahulu.');
  return db;
}
