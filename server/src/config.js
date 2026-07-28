// Konfigurasi terpusat — dibaca dari environment variable (lihat .env.example).
// Prinsip: secret & path tidak di-hardcode (lihat SECURITY.md).
import 'dotenv/config';
import path from 'node:path';

function bool(value, fallback) {
  if (value === undefined) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(String(value).toLowerCase());
}

function int(value, fallback) {
  const n = Number.parseInt(value, 10);
  return Number.isFinite(n) ? n : fallback;
}

const config = {
  port: int(process.env.PORT, 3000),

  // Root HDD eksternal tempat semua file user disimpan.
  storageMountPath: path.resolve(process.env.STORAGE_MOUNT_PATH || '/mnt/hestia'),

  // Bila true, Storage Manager mensyaratkan path benar-benar sebuah mount point.
  requireMount: bool(process.env.REQUIRE_MOUNT, false),

  // Lokasi database SQLite (metadata).
  dbPath: path.resolve(process.env.DB_PATH || './data/hestia.db'),

  // Auth (Tahap 2).
  jwtSecret: process.env.JWT_SECRET || '',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '30d',

  // Dipakai pada tahap berikutnya (Upload).
  maxUploadSize: int(process.env.MAX_UPLOAD_SIZE, 2 * 1024 * 1024 * 1024),

  env: process.env.NODE_ENV || 'development',
};

export default config;
