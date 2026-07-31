# Changelog

Semua perubahan penting pada Hestia dicatat di file ini.
Format mengikuti [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Struktur & Rilis (2026-07-31)

#### Changed
- Restrukturisasi repositori menjadi dua bagian: `backend/` (server Node.js) dan
  `frontend/` (aplikasi Flutter), agar batas backend & frontend jelas.
- Upload di aplikasi kini mengambil media **langsung dari galeri** (Photo Picker sistem)
  memakai `image_picker`, menggantikan pemilih berkas `file_picker`.

#### Added
- Ikon aplikasi Hestia (lambang api perapian) di-generate via `flutter_launcher_icons`;
  label aplikasi diset "Hestia".

#### Fixed
- Konfigurasi build Android: `compileSdk` diset ke 36 dan seluruh plugin diselaraskan —
  mengatasi kegagalan build rilis akibat ketidakcocokan versi SDK antar-plugin.
- Manifest menambahkan izin `INTERNET` dan `usesCleartextTraffic="true"` agar APK **rilis**
  dapat terhubung ke server di jaringan lokal (HTTP).

### Aplikasi Mobile — Flutter (2026-07-29)

Aplikasi mobile Android sebagai klien Hestia (`frontend/app`).

#### Added
- Alur autentikasi: setup alamat server → splash (restore sesi via `/auth/me`) → login & register.
- Navigasi utama 4 tab: **Jelajah**, **Upload**, **Riwayat**, **Pengaturan**, dengan banner
  status penyimpanan yang menyegar otomatis.
- **Jelajah**: grid thumbnail (cache + header `Authorization`) dan paginasi infinite scroll.
- **Upload**: pilih banyak foto/video, indikator progres, otomatis nonaktif bila storage server tidak tersedia.
- **Download**: simpan ke penyimpanan sementara lalu buka/bagikan via share sheet OS.
- **Riwayat** upload & **Pengaturan** server (ubah alamat server, logout).
- Token disimpan di `flutter_secure_storage`; state via `provider`; HTTP via `dio` (interceptor Authorization).

### Tahap 3 — File Backend (2026-07-28)
Upload, browse, download, delete, thumbnail, dan riwayat.

#### Added
- `POST /api/upload` — multipart, single & multiple file, field `path` untuk subfolder.
  Balas `{ uploaded, failed }`. Menolak `503` bila HDD tidak tersedia (guard `checkStorage`).
- `GET /api/files` — browse folder + paginasi (`path`, `page`, `limit`, `sort`), daftar folder & file.
- `GET /api/files/:id` — detail metadata file.
- `GET /api/files/:id/thumb` — thumbnail (binary), `404` bila belum ada.
- `GET /api/download/:id` — stream file asli dari HDD, mendukung HTTP Range (206).
- `DELETE /api/files/:id` — hapus metadata + file fisik + thumbnail.
- `GET /api/history` — riwayat upload (success/failed) per user.
- Thumbnail service gambar (`sharp`, lebar 320px JPEG, hormati EXIF) — best-effort, video di-skip di MVP.
- Storage layout per-user: `Users/<id>/media`, `Users/<id>/.thumbs`, `Users/<id>/.incoming` — `server/src/storage/paths.js`.
- Data access file & history — `server/src/db/files.js`.
- Deps: `multer` (upload), `sharp` (thumbnail).

#### Security
- Validasi anti path-traversal untuk nama file & subfolder (`server/src/utils/paths.js`,
  `safeResolve` menjamin path tetap di dalam area user).
- Hanya menerima `image/*` & `video/*`; tipe lain ditolak (`UNSUPPORTED_TYPE`).
- Batas ukuran upload (`MAX_UPLOAD_SIZE`) → `413` bila melebihi.
- Authorization per-user: akses file milik orang lain → `403` (`server/src/middleware/ownFile.js`).
- File upload disimpan lalu dibaca ulang, tidak pernah dieksekusi.

#### Notes
- Folder user memakai `id` (mis. `Users/1/`) demi keunikan & keamanan nama.
- Diuji manual end-to-end: upload 1/banyak, subfolder, tipe ditolak, browse root & subfolder,
  detail, thumbnail, download (byte identik), Range 206, isolasi antar-user 403, history,
  delete (file hilang dari HDD), guard 503, dan path traversal 400 (tanpa kebocoran file).

### Tahap 2 — Auth Backend (2026-07-28)
Autentikasi berbasis email + JWT.

#### Added
- `POST /api/auth/register` — daftar akun (email, password, display_name), balas user + JWT.
- `POST /api/auth/login` — login, balas user + JWT. Pesan error generik (anti user-enumeration).
- `GET /api/auth/me` — profil user dari token (butuh auth).
- Password hashing dengan bcrypt (`bcryptjs`, 12 rounds) — `server/src/auth/password.js`.
- JWT sign/verify (`jsonwebtoken`) — `server/src/auth/jwt.js`. Secret wajib di produksi;
  di dev pakai secret ephemeral bila `JWT_SECRET` kosong.
- Middleware `requireAuth` (`server/src/middleware/auth.js`) — verifikasi `Bearer` token + cek user masih ada.
- Rate limiter endpoint auth (10 req / 15 menit / IP) — `server/src/middleware/rateLimit.js`.
- Validasi input email & password (min 8 karakter), email dinormalisasi lowercase — `server/src/utils/validate.js`.
- User data access — `server/src/db/users.js` (create / findByEmail / findById / toPublicUser).
- `GET /api/storage/status` kini dilindungi `requireAuth`.
- Config baru: `JWT_EXPIRES_IN` (default `30d`).

#### Security
- Password tidak pernah disimpan plaintext; hash tidak pernah dikembalikan ke klien.
- Verifikasi password dijalankan walau user tidak ada (mitigasi timing attack).

#### Notes
- Diuji manual end-to-end (9 skenario): register, duplicate email, password lemah,
  login benar/salah, `/me` dengan & tanpa token, `/storage/status` dengan & tanpa token — semua sesuai harapan.

### Tahap 1 — Fondasi Backend (2026-07-28)
Fondasi server API. Belum ada auth/upload (menyusul di Tahap 2 & 3).

#### Added
- Struktur project backend di `server/` (Node.js + Express, ES modules).
- Konfigurasi via environment variable (`server/src/config.js`, `server/.env.example`):
  `PORT`, `STORAGE_MOUNT_PATH`, `REQUIRE_MOUNT`, `DB_PATH`, `JWT_SECRET`, `MAX_UPLOAD_SIZE`.
- Database SQLite (better-sqlite3) dengan skema `users`, `files`, `upload_history`
  (`server/src/db/`), mode WAL, foreign keys aktif.
- Storage Manager (`server/src/storage/manager.js`): deteksi HDD eksternal —
  cek path ada, mount point (bandingkan device id), writable, dan kapasitas disk (statfs).
  Auto-membuat layout `Users/`, `Shared/`, `System/` saat storage tersedia.
- Endpoint `GET /api/storage/status` — melaporkan ketersediaan HDD + total/free bytes.
- Endpoint `GET /api/health` — health check.
- Format error API standar `{ error: { code, message } }`.
- Error handler terpusat yang tidak membocorkan detail internal.
- `.gitignore` (root) — mengecualikan `node_modules/`, `.env`, dan `data/`.

#### Notes
- `DB_PATH` default dev: `./data/hestia.db`. Produksi disarankan diarahkan ke
  `<STORAGE_MOUNT_PATH>/System/hestia.db` agar ikut ter-backup bersama HDD.
- `REQUIRE_MOUNT=false` untuk dev tanpa HDD; set `true` di produksi.
- Diuji manual: server jalan, health OK, storage status benar untuk kondisi
  HDD tidak ada / tersedia, tabel DB terbentuk, folder layout otomatis dibuat.

[Unreleased]: https://github.com/rinorouu/hestia
