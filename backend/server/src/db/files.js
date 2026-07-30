// Data access untuk tabel files & upload_history.
import { getDb } from './index.js';

// Sisipkan metadata file baru. Mengembalikan baris file.
export function insertFile({ userId, filename, relPath, mimeType, sizeBytes, thumbPath = null, checksum = null, takenAt = null }) {
  const db = getDb();
  const info = db
    .prepare(
      `INSERT INTO files (user_id, filename, rel_path, mime_type, size_bytes, thumb_path, checksum, taken_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(userId, filename, relPath, mimeType, sizeBytes, thumbPath, checksum, takenAt);
  return findFileById(info.lastInsertRowid);
}

export function setThumbPath(fileId, thumbPath) {
  getDb().prepare(`UPDATE files SET thumb_path = ? WHERE id = ?`).run(thumbPath, fileId);
}

export function findFileById(id) {
  return getDb().prepare(`SELECT * FROM files WHERE id = ?`).get(id);
}

export function deleteFile(id) {
  getDb().prepare(`DELETE FROM files WHERE id = ?`).run(id);
}

// File yang berada LANGSUNG di dalam `dir` (relatif media root, '' = root).
// Dengan paginasi & pengurutan.
export function listFilesInDir(userId, dir, { page = 1, limit = 50, sort = 'uploaded_at' } = {}) {
  const db = getDb();
  const orderBy = {
    uploaded_at: 'uploaded_at DESC',
    filename: 'filename COLLATE NOCASE ASC',
    size: 'size_bytes DESC',
  }[sort] || 'uploaded_at DESC';

  // Kondisi "berada langsung di dir": prefix cocok tapi tanpa '/' lebih dalam.
  const prefix = dir ? `${dir}/` : '';
  const like = `${prefix}%`;
  const deeper = `${prefix}%/%`;
  const where = `user_id = ? AND rel_path LIKE ? AND rel_path NOT LIKE ?`;
  const args = [userId, like, deeper];

  const total = db.prepare(`SELECT COUNT(*) AS n FROM files WHERE ${where}`).get(...args).n;
  const offset = (Math.max(1, page) - 1) * limit;
  const rows = db
    .prepare(`SELECT * FROM files WHERE ${where} ORDER BY ${orderBy} LIMIT ? OFFSET ?`)
    .all(...args, limit, offset);

  return { rows, total };
}

// Nama folder (immediate subdirectories) di dalam `dir`.
export function listSubfolders(userId, dir) {
  const prefix = dir ? `${dir}/` : '';
  const deeper = `${prefix}%/%`;
  const rows = getDb()
    .prepare(`SELECT DISTINCT rel_path FROM files WHERE user_id = ? AND rel_path LIKE ?`)
    .all(userId, deeper);

  const names = new Set();
  for (const { rel_path } of rows) {
    const rest = rel_path.slice(prefix.length); // sisa setelah dir
    const seg = rest.split('/')[0];
    if (seg) names.add(seg);
  }
  return [...names].sort((a, b) => a.localeCompare(b));
}

// Riwayat upload (upload_history).
export function recordHistory({ userId, fileId = null, status, message = null }) {
  getDb()
    .prepare(`INSERT INTO upload_history (user_id, file_id, status, message) VALUES (?, ?, ?, ?)`)
    .run(userId, fileId, status, message);
}

export function listHistory(userId, { limit = 50 } = {}) {
  return getDb()
    .prepare(`SELECT id, file_id, status, message, created_at
              FROM upload_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ?`)
    .all(userId, limit);
}
