// Rate limiting untuk endpoint auth — mitigasi brute force (docs/SECURITY.md).
import rateLimit from 'express-rate-limit';
import { sendError } from '../utils/errors.js';

// Maks 10 percobaan per 15 menit per IP untuk register/login.
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    sendError(res, 429, 'TOO_MANY_REQUESTS', 'Terlalu banyak percobaan. Coba lagi nanti.');
  },
});
