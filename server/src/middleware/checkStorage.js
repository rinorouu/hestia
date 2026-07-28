// Guard storage — menolak operasi tulis bila HDD tidak tersedia (503).
// (docs/PROJECT_VISION.md: "Apabila HDD belum terhubung ... tidak menerima upload".)
import { getStorageStatus } from '../storage/manager.js';
import { ensureUserDirs } from '../storage/paths.js';
import { sendError } from '../utils/errors.js';

export function checkStorage(req, res, next) {
  const status = getStorageStatus();
  if (!status.available) {
    return sendError(res, 503, 'STORAGE_UNAVAILABLE', 'Media penyimpanan tidak tersedia.');
  }
  ensureUserDirs(req.user.id);
  next();
}
