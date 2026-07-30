// Thumbnail service — generate thumbnail gambar dengan sharp.
// Best-effort: kegagalan tidak menggagalkan upload. Video di-skip di MVP
// (thumb_path tetap null → app menampilkan placeholder). Lihat docs/ARCHITECTURE.md.
import fs from 'node:fs';
import path from 'node:path';
import sharp from 'sharp';
import { thumbsRoot } from '../storage/paths.js';

const THUMB_WIDTH = 320;

export function isImage(mimeType) {
  return typeof mimeType === 'string' && mimeType.startsWith('image/');
}

// Membuat thumbnail untuk file gambar. Mengembalikan path absolut thumbnail,
// atau null bila tidak dibuat (bukan gambar / gagal).
export async function generateThumbnail({ userId, fileId, sourcePath, mimeType }) {
  if (!isImage(mimeType)) return null;
  try {
    const dir = thumbsRoot(userId);
    fs.mkdirSync(dir, { recursive: true });
    const dest = path.join(dir, `${fileId}.jpg`);
    await sharp(sourcePath)
      .rotate() // hormati orientasi EXIF
      .resize({ width: THUMB_WIDTH, withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toFile(dest);
    return dest;
  } catch (err) {
    console.warn(`[thumb]   Gagal membuat thumbnail file #${fileId}: ${err.message}`);
    return null;
  }
}
