// Middleware autentikasi — memverifikasi header Authorization: Bearer <token>.
import { verifyToken } from '../auth/jwt.js';
import { findById } from '../db/users.js';
import { sendError } from '../utils/errors.js';

export function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Token tidak ada atau format salah.');
  }

  const payload = verifyToken(token);
  if (!payload) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Token tidak valid atau kadaluarsa.');
  }

  // Pastikan user masih ada (mis. akun dihapus setelah token terbit).
  const user = findById(Number(payload.sub));
  if (!user) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Akun tidak ditemukan.');
  }

  req.user = user; // { id, email, display_name, role, created_at }
  next();
}
