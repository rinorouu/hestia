// Penandatanganan & verifikasi JWT. Secret dari env (docs/SECURITY.md).
import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import config from '../config.js';

// Resolusi secret:
// - Bila JWT_SECRET diset → pakai itu.
// - Bila kosong di production → GAGAL (fail fast, jangan pakai secret lemah).
// - Bila kosong di development → secret ephemeral acak + peringatan
//   (token akan invalid setelah server restart — hanya untuk dev).
function resolveSecret() {
  if (config.jwtSecret && config.jwtSecret !== 'change-me-to-a-long-random-string') {
    return config.jwtSecret;
  }
  if (config.env === 'production') {
    throw new Error('JWT_SECRET wajib diset di production. Lihat .env.example / docs/SECURITY.md.');
  }
  console.warn('[auth]    JWT_SECRET belum diset — memakai secret ephemeral (dev). Token invalid setelah restart.');
  return crypto.randomBytes(48).toString('hex');
}

const SECRET = resolveSecret();

export function signToken(user) {
  return jwt.sign(
    { role: user.role },
    SECRET,
    { subject: String(user.id), expiresIn: config.jwtExpiresIn }
  );
}

// Mengembalikan payload bila valid, atau null bila invalid/kadaluarsa.
export function verifyToken(token) {
  try {
    return jwt.verify(token, SECRET);
  } catch {
    return null;
  }
}
