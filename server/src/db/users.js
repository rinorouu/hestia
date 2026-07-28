// Data access untuk tabel users.
import { getDb } from './index.js';

// Membuat user baru. Mengembalikan baris user (tanpa password_hash).
// Melempar error dengan code 'EMAIL_TAKEN' bila email sudah dipakai.
export function createUser({ email, passwordHash, displayName, role = 'user' }) {
  const db = getDb();
  try {
    const info = db
      .prepare(
        `INSERT INTO users (email, password_hash, display_name, role)
         VALUES (?, ?, ?, ?)`
      )
      .run(email, passwordHash, displayName || null, role);
    return findById(info.lastInsertRowid);
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      const e = new Error('Email sudah terdaftar.');
      e.code = 'EMAIL_TAKEN';
      throw e;
    }
    throw err;
  }
}

// Cari user berdasarkan email — termasuk password_hash (untuk verifikasi login).
export function findByEmailWithHash(email) {
  return getDb()
    .prepare(`SELECT id, email, password_hash, display_name, role, created_at
              FROM users WHERE email = ?`)
    .get(email);
}

// Cari user berdasarkan id — TANPA password_hash (aman dikembalikan ke klien).
export function findById(id) {
  return getDb()
    .prepare(`SELECT id, email, display_name, role, created_at
              FROM users WHERE id = ?`)
    .get(id);
}

// Bentuk objek user publik yang konsisten untuk respons API.
export function toPublicUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    email: row.email,
    display_name: row.display_name,
    role: row.role,
  };
}
