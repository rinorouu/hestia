// Route storage — GET /api/storage/status
// (Sesuai docs/API_SPEC.md bagian Storage.)
// Auth diterapkan saat mounting di app.js (requireAuth).
import { Router } from 'express';
import { getStorageStatus } from '../storage/manager.js';

const router = Router();

router.get('/status', (req, res) => {
  const status = getStorageStatus();
  res.json({
    available: status.available,
    reason: status.reason,
    total_bytes: status.total_bytes,
    free_bytes: status.free_bytes,
  });
});

export default router;
