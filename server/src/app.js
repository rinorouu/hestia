// Membangun aplikasi Express (tanpa memulai listen) — memudahkan pengujian.
import express from 'express';
import authRoutes from './routes/auth.js';
import storageRoutes from './routes/storage.js';
import fileRoutes from './routes/files.js';
import historyRoutes from './routes/history.js';
import { requireAuth } from './middleware/auth.js';
import { sendError } from './utils/errors.js';

export function createApp() {
  const app = express();

  app.use(express.json());

  // Health check sederhana.
  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', service: 'hestia', version: '0.1.0' });
  });

  // Routes.
  app.use('/api/auth', authRoutes);
  app.use('/api/storage', requireAuth, storageRoutes);   // butuh auth (Tahap 2)
  app.use('/api/history', requireAuth, historyRoutes);   // Tahap 3
  app.use('/api', requireAuth, fileRoutes);              // /upload, /files, /download (Tahap 3)

  // 404 untuk route tak dikenal.
  app.use((req, res) => {
    sendError(res, 404, 'NOT_FOUND', 'Resource tidak ditemukan.');
  });

  // Error handler terpusat — jangan bocorkan detail internal ke klien (SECURITY.md).
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    console.error('[error]', err);
    sendError(res, 500, 'INTERNAL_ERROR', 'Terjadi kesalahan pada server.');
  });

  return app;
}
