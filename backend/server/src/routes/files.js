// Routes file — upload, browse, detail, download, thumbnail, delete.
// Sesuai docs/API_SPEC.md. Semua butuh auth (dipasang di app.js).
import fs from 'node:fs';
import path from 'node:path';
import { Router } from 'express';
import { checkStorage } from '../middleware/checkStorage.js';
import { loadOwnedFile } from '../middleware/ownFile.js';
import { runUpload } from '../media/upload.js';
import { generateThumbnail } from '../media/thumbnail.js';
import { mediaRoot } from '../storage/paths.js';
import { sanitizeFilename, sanitizeSubPath, safeResolve } from '../utils/paths.js';
import { toPublicFile, toDetailedFile } from '../utils/serialize.js';
import { sendError, asyncHandler } from '../utils/errors.js';
import {
  insertFile,
  setThumbPath,
  deleteFile,
  listFilesInDir,
  listSubfolders,
  recordHistory,
} from '../db/files.js';

const router = Router();

// Hapus file sementara (best-effort).
function cleanupTemp(files = []) {
  for (const f of files) {
    try { fs.unlinkSync(f.path); } catch { /* abaikan */ }
  }
}

// Cari nama file unik di dalam dir (hindari menimpa file yang sudah ada).
function uniqueName(dir, name) {
  const ext = path.extname(name);
  const base = name.slice(0, name.length - ext.length);
  let candidate = name;
  let i = 0;
  while (fs.existsSync(path.join(dir, candidate))) {
    i += 1;
    candidate = `${base}-${i}${ext}`;
  }
  return candidate;
}

// POST /api/upload  (multipart: files[], path?)
router.post(
  '/upload',
  checkStorage,
  runUpload,
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const files = req.files || [];

    // File yang ditolak filter (tipe tidak didukung).
    const failed = (req.rejectedFiles || []).map((r) => {
      recordHistory({ userId, status: 'failed', message: `${r.filename}: ${r.reason}` });
      return r;
    });

    // Tentukan folder tujuan dari `path` (setelah multipart selesai di-parse).
    let destDir;
    let subDir;
    try {
      subDir = sanitizeSubPath(req.body?.path);
      destDir = safeResolve(mediaRoot(userId), subDir);
      fs.mkdirSync(destDir, { recursive: true });
    } catch (err) {
      cleanupTemp(files);
      if (err.code === 'INVALID_PATH') {
        return sendError(res, 400, 'INVALID_PATH', 'Folder tujuan tidak valid.');
      }
      throw err;
    }

    const uploaded = [];
    for (const file of files) {
      try {
        const safeName = uniqueName(destDir, sanitizeFilename(file.originalname));
        const finalPath = path.join(destDir, safeName);
        fs.renameSync(file.path, finalPath); // pindah dari .incoming ke media/

        const relPath = subDir ? `${subDir}/${safeName}` : safeName;
        const row = insertFile({
          userId,
          filename: safeName,
          relPath,
          mimeType: file.mimetype,
          sizeBytes: file.size,
        });

        // Thumbnail best-effort (tidak menggagalkan upload).
        const thumb = await generateThumbnail({
          userId,
          fileId: row.id,
          sourcePath: finalPath,
          mimeType: file.mimetype,
        });
        if (thumb) {
          setThumbPath(row.id, thumb);
          row.thumb_path = thumb;
        }

        recordHistory({ userId, fileId: row.id, status: 'success' });
        uploaded.push(toPublicFile(row));
      } catch (err) {
        cleanupTemp([file]);
        recordHistory({ userId, status: 'failed', message: `${file.originalname}: ${err.message}` });
        failed.push({ filename: file.originalname, reason: 'WRITE_FAILED' });
      }
    }

    res.status(201).json({ uploaded, failed });
  })
);

// GET /api/files  (browse folder + paginasi)
router.get(
  '/files',
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    let dir;
    try {
      dir = sanitizeSubPath(req.query.path);
    } catch {
      return sendError(res, 400, 'INVALID_PATH', 'Path tidak valid.');
    }
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(200, Math.max(1, parseInt(req.query.limit, 10) || 50));
    const sort = req.query.sort || 'uploaded_at';

    const { rows, total } = listFilesInDir(userId, dir, { page, limit, sort });
    const folders = listSubfolders(userId, dir).map((name) => ({
      name,
      path: dir ? `/${dir}/${name}` : `/${name}`,
    }));

    res.json({
      path: dir ? `/${dir}` : '/',
      folders,
      files: rows.map(toPublicFile),
      page,
      total,
    });
  })
);

// GET /api/files/:id  (detail)
router.get('/files/:id', loadOwnedFile, (req, res) => {
  res.json(toDetailedFile(req.ownedFile));
});

// GET /api/files/:id/thumb  (binary)
router.get('/files/:id/thumb', loadOwnedFile, (req, res) => {
  const file = req.ownedFile;
  if (!file.thumb_path || !fs.existsSync(file.thumb_path)) {
    return sendError(res, 404, 'NOT_FOUND', 'Thumbnail tidak tersedia.');
  }
  res.sendFile(path.resolve(file.thumb_path));
});

// GET /api/download/:id  (stream file asli, mendukung Range)
router.get('/download/:id', loadOwnedFile, (req, res) => {
  const file = req.ownedFile;
  let absPath;
  try {
    absPath = safeResolve(mediaRoot(file.user_id), file.rel_path);
  } catch {
    return sendError(res, 400, 'INVALID_PATH', 'Path file tidak valid.');
  }
  if (!fs.existsSync(absPath)) {
    return sendError(res, 404, 'NOT_FOUND', 'File tidak ditemukan di storage.');
  }
  // res.sendFile menangani Range/Content-Type; set nama file untuk unduhan.
  res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(file.filename)}"`);
  if (file.mime_type) res.type(file.mime_type);
  res.sendFile(absPath, (err) => {
    if (err && !res.headersSent) {
      sendError(res, 404, 'NOT_FOUND', 'File tidak dapat dibaca.');
    }
  });
});

// DELETE /api/files/:id  (hapus metadata + file + thumbnail)
router.delete('/files/:id', loadOwnedFile, (req, res) => {
  const file = req.ownedFile;
  // Hapus file fisik (best-effort) — metadata tetap dihapus agar konsisten.
  try {
    const absPath = safeResolve(mediaRoot(file.user_id), file.rel_path);
    if (fs.existsSync(absPath)) fs.unlinkSync(absPath);
  } catch { /* abaikan */ }
  if (file.thumb_path) {
    try { fs.unlinkSync(file.thumb_path); } catch { /* abaikan */ }
  }
  deleteFile(file.id);
  res.json({ deleted: true, id: file.id });
});

export default router;
