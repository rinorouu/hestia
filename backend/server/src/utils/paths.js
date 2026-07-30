// Utilitas keamanan path — mencegah path traversal (docs/SECURITY.md).
import path from 'node:path';

const ILLEGAL = new Set(['<', '>', ':', '"', '|', '?', '*', '/', '\\']);

// Buang karakter kontrol (charCode < 32) dan karakter ilegal filesystem.
function stripUnsafe(str) {
  let out = '';
  for (const ch of str) {
    if (ch.charCodeAt(0) < 32) continue;
    out += ILLEGAL.has(ch) ? '_' : ch;
  }
  return out;
}

// Bersihkan nama file: ambil basename saja, buang karakter berbahaya/kontrol.
export function sanitizeFilename(name) {
  const base = path.basename(String(name || '')).trim();
  const cleaned = stripUnsafe(base)
    .replace(/^\.+/, '') // jangan diawali titik (hidden/relatif)
    .slice(0, 200);
  return cleaned || 'file';
}

// Bersihkan sub-path (folder tujuan/browse) relatif terhadap root user.
// Menolak '..', path absolut, dan menghasilkan path relatif berpemisah '/'.
// Mengembalikan '' untuk root.
export function sanitizeSubPath(sub) {
  if (!sub || typeof sub !== 'string') return '';
  const parts = sub
    .replace(/\\/g, '/')
    .split('/')
    .map((s) => s.trim())
    .filter((s) => s && s !== '.');
  for (const seg of parts) {
    if (seg === '..') {
      const e = new Error('Path tidak valid.');
      e.code = 'INVALID_PATH';
      throw e;
    }
  }
  return parts.map((s) => sanitizeFilename(s)).join('/');
}

// Resolusi absolut yang dijamin berada di dalam `root`. Melempar bila keluar.
export function safeResolve(root, rel) {
  const rootResolved = path.resolve(root);
  const abs = path.resolve(rootResolved, rel);
  if (abs !== rootResolved && !abs.startsWith(rootResolved + path.sep)) {
    const e = new Error('Path di luar area yang diizinkan.');
    e.code = 'INVALID_PATH';
    throw e;
  }
  return abs;
}
