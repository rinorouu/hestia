// Routes autentikasi — sesuai docs/API_SPEC.md bagian Auth.
import { Router } from 'express';
import { authLimiter } from '../middleware/rateLimit.js';
import { requireAuth } from '../middleware/auth.js';
import { validateCredentials } from '../utils/validate.js';
import { hashPassword, verifyPassword } from '../auth/password.js';
import { signToken } from '../auth/jwt.js';
import {
  createUser,
  findByEmailWithHash,
  toPublicUser,
} from '../db/users.js';
import { sendError, asyncHandler } from '../utils/errors.js';

const router = Router();

// POST /api/auth/register
router.post(
  '/register',
  authLimiter,
  asyncHandler(async (req, res) => {
    const { email, password, display_name } = req.body || {};
    const check = validateCredentials({ email, password });
    if (!check.valid) return sendError(res, 400, 'INVALID_INPUT', check.message);

    try {
      const passwordHash = await hashPassword(check.value.password);
      const user = createUser({
        email: check.value.email,
        passwordHash,
        displayName: typeof display_name === 'string' ? display_name.trim() : null,
      });
      const token = signToken(user);
      return res.status(201).json({ user: toPublicUser(user), token });
    } catch (err) {
      if (err.code === 'EMAIL_TAKEN') {
        return sendError(res, 400, 'EMAIL_TAKEN', 'Email sudah terdaftar.');
      }
      throw err;
    }
  })
);

// POST /api/auth/login
router.post(
  '/login',
  authLimiter,
  asyncHandler(async (req, res) => {
    const { email, password } = req.body || {};
    const check = validateCredentials({ email, password });
    // Pesan generik agar tidak membocorkan info (docs/SECURITY.md).
    if (!check.valid) return sendError(res, 401, 'INVALID_CREDENTIALS', 'Email atau password salah.');

    const row = findByEmailWithHash(check.value.email);
    // Selalu jalankan verifikasi untuk mengurangi timing leak; pakai hash dummy bila user tak ada.
    const ok = row
      ? await verifyPassword(check.value.password, row.password_hash)
      : await verifyPassword(check.value.password, '$2a$12$0000000000000000000000000000000000000000000000000000');

    if (!row || !ok) {
      return sendError(res, 401, 'INVALID_CREDENTIALS', 'Email atau password salah.');
    }

    const token = signToken(row);
    return res.json({ user: toPublicUser(row), token });
  })
);

// GET /api/auth/me
router.get('/me', requireAuth, (req, res) => {
  res.json(toPublicUser(req.user));
});

export default router;
