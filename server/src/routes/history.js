// Route riwayat upload — GET /api/history (docs/API_SPEC.md).
import { Router } from 'express';
import { listHistory } from '../db/files.js';

const router = Router();

router.get('/', (req, res) => {
  const limit = Math.min(200, Math.max(1, parseInt(req.query.limit, 10) || 50));
  const items = listHistory(req.user.id, { limit });
  res.json({ items });
});

export default router;
