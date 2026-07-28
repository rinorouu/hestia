// Konfigurasi multer untuk menerima upload ke area sementara (.incoming),
// lalu handler memindahkannya ke media/. Batas ukuran & tipe divalidasi di sini.
import crypto from 'node:crypto';
import path from 'node:path';
import multer from 'multer';
import config from '../config.js';
import { incomingRoot } from '../storage/paths.js';
import { sendError } from '../utils/errors.js';

const storage = multer.diskStorage({
  destination(req, file, cb) {
    // .incoming dipastikan ada oleh middleware checkStorage sebelumnya.
    cb(null, incomingRoot(req.user.id));
  },
  filename(req, file, cb) {
    const rand = crypto.randomBytes(8).toString('hex');
    cb(null, `${Date.now()}-${rand}${path.extname(file.originalname).slice(0, 12)}`);
  },
});

// Hanya terima gambar & video. File lain ditandai ditolak (tanpa ditulis).
function fileFilter(req, file, cb) {
  const ok = /^(image|video)\//.test(file.mimetype || '');
  if (!ok) {
    (req.rejectedFiles ||= []).push({
      filename: file.originalname,
      reason: 'UNSUPPORTED_TYPE',
    });
    return cb(null, false);
  }
  cb(null, true);
}

const multerUpload = multer({
  storage,
  fileFilter,
  limits: { fileSize: config.maxUploadSize },
}).array('files');

// Bungkus untuk memetakan error multer ke format API standar.
export function runUpload(req, res, next) {
  multerUpload(req, res, (err) => {
    if (!err) return next();
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return sendError(res, 413, 'FILE_TOO_LARGE', 'Ukuran file melebihi batas.');
      }
      return sendError(res, 400, 'UPLOAD_ERROR', 'Upload gagal diproses.');
    }
    next(err);
  });
}
