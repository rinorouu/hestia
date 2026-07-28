// Middleware authorization file — memuat file milik user dari :id.
// 404 bila tidak ada, 403 bila bukan pemilik (kecuali admin). (docs/SECURITY.md)
import { findFileById } from '../db/files.js';
import { sendError } from '../utils/errors.js';

export function loadOwnedFile(req, res, next) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) {
    return sendError(res, 400, 'INVALID_INPUT', 'Id file tidak valid.');
  }
  const file = findFileById(id);
  if (!file) {
    return sendError(res, 404, 'NOT_FOUND', 'File tidak ditemukan.');
  }
  if (file.user_id !== req.user.id && req.user.role !== 'admin') {
    return sendError(res, 403, 'FORBIDDEN', 'Tidak berhak mengakses file ini.');
  }
  req.ownedFile = file;
  next();
}
