<div align="center">

# 🏛️ Hestia

**Self-hosted photo & video storage untuk keluarga.**

Simpan, akses, dan kelola foto serta video dari smartphone ke HDD eksternal
di server pribadimu — sederhana, cepat, ringan, dan sepenuhnya privat.

![status](https://img.shields.io/badge/status-in%20development-orange)
![backend](https://img.shields.io/badge/backend-Node.js%20%2B%20Express-green)
![mobile](https://img.shields.io/badge/mobile-Flutter-blue)
![db](https://img.shields.io/badge/db-SQLite-lightgrey)

</div>

---

## 📖 Tentang Hestia

**Hestia** adalah aplikasi penyimpanan foto & video yang berjalan di **server pribadi**
(mini PC, Raspberry Pi, atau home server) dan menyimpan seluruh file langsung ke
**HDD eksternal** milikmu.

Tujuannya bukan meniru Google Photos atau Immich, melainkan menyediakan solusi
penyimpanan keluarga yang **privat, ringan, dan mudah digunakan**. Setiap anggota
keluarga punya akun sendiri, ruang penyimpanan sendiri, dan hak akses sendiri.
Semua data tetap berada di perangkatmu — **tidak ada cloud pihak ketiga.**

> Nama "Hestia" diambil dari dewi perapian & rumah dalam mitologi Yunani —
> melambangkan tempat yang aman untuk menyimpan kenangan keluarga.

**Prinsip:** Simple · Fast · Lightweight · Privacy First · Offline Friendly

---

## ✨ Fitur

- 🔐 **Registrasi & login** — akun berbasis email + password, autentikasi token (JWT).
- 👨‍👩‍👧‍👦 **Multi-user** — banyak akun dalam satu server, penyimpanan tiap user terisolasi.
- ⬆️ **Upload foto & video** — satu atau banyak file sekaligus, mendukung subfolder.
- 🗂️ **Browse file** — jelajahi folder, lihat thumbnail, ukuran, dan tanggal upload.
- 🖼️ **Thumbnail otomatis** — pratinjau gambar dibuat otomatis saat upload.
- ⬇️ **Download** — ambil file kembali ke smartphone (mendukung resume/streaming).
- 🕘 **Riwayat upload** — catatan file yang berhasil & gagal diunggah.
- 💽 **Deteksi HDD** — upload otomatis ditolak bila HDD eksternal belum terpasang.
- 🔒 **Aman** — password di-hash, isolasi antar-user, proteksi path & validasi file.

**Direncanakan:** aplikasi Android (Flutter), Auto Sync, album, favorite, pencarian,
share link, recycle bin, dan enkripsi penyimpanan.

---

## 🧰 Tools yang Digunakan

| Kategori | Teknologi |
|----------|-----------|
| **Bahasa & Runtime** | Node.js (JavaScript) |
| **Web Framework** | Express |
| **Database** | SQLite (menyimpan metadata; file asli di HDD) |
| **Autentikasi** | JSON Web Token (JWT) + bcrypt (hashing password) |
| **Upload File** | Multer |
| **Pemrosesan Gambar** | Sharp (thumbnail) |
| **Aplikasi Mobile** | Flutter / Dart *(dalam pengembangan)* |
| **Keamanan Akses** | express-rate-limit, HTTPS (reverse proxy) |

---

## 💻 System Requirements

### Server (untuk menjalankan Hestia)

| Komponen | Minimum | Rekomendasi |
|----------|---------|-------------|
| **Sistem Operasi** | Linux / Windows / macOS | Linux (mini PC / Raspberry Pi 4+) |
| **Node.js** | v20 atau lebih baru | v20 LTS |
| **RAM** | 512 MB | 1 GB atau lebih |
| **Penyimpanan** | HDD eksternal | HDD + HDD kedua untuk backup |
| **Jaringan** | LAN (jaringan lokal) | LAN + domain & HTTPS untuk akses internet |

> 💡 **Belum punya/pasang HDD?** Untuk uji coba, penyimpanan bisa diarahkan ke folder
> biasa (atur `REQUIRE_MOUNT=false`). HDD fisik baru diperlukan untuk penggunaan nyata.

### Perangkat pengguna (keluarga)

- Smartphone **Android**.
- Aplikasi dipasang langsung via file **APK** (tidak wajib lewat Play Store).

---

## 🚀 Cara Install

### 1. Prasyarat
Pastikan sudah terpasang:
- [Node.js ≥ 20](https://nodejs.org/) (termasuk npm)
- [Git](https://git-scm.com/)

### 2. Ambil kode
```bash
git clone https://github.com/rinorouu/hestia.git
cd hestia/server
```

### 3. Install dependencies
```bash
npm install
```

### 4. Siapkan konfigurasi
```bash
cp .env.example .env
```
Lalu buka `.env` dan sesuaikan. Yang penting:
- **`JWT_SECRET`** — isi dengan string acak panjang. Generate cepat:
  ```bash
  node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
  ```
- **`STORAGE_MOUNT_PATH`** — lokasi penyimpanan (mount HDD, atau folder biasa untuk uji coba).
- **`REQUIRE_MOUNT`** — `false` untuk uji coba tanpa HDD, `true` untuk produksi.

### 5. Jalankan server
```bash
npm start        # mode normal
npm run dev      # mode pengembangan (auto-reload)
```

Server berjalan di **`http://localhost:3000`**. Cek dengan membuka `http://localhost:3000/api/health`
— jika membalas `{"status":"ok"}`, server siap digunakan. 🎉

---

## ⚙️ Konfigurasi

| Variabel | Default | Keterangan |
|----------|---------|------------|
| `PORT` | `3000` | Port HTTP server |
| `STORAGE_MOUNT_PATH` | `/mnt/hestia` | Lokasi penyimpanan (mount HDD) |
| `REQUIRE_MOUNT` | `false` | `true` = wajibkan HDD benar-benar ter-mount |
| `DB_PATH` | `./data/hestia.db` | Lokasi database SQLite |
| `JWT_SECRET` | — | **Wajib** diisi di produksi |
| `JWT_EXPIRES_IN` | `30d` | Masa berlaku token login |
| `MAX_UPLOAD_SIZE` | `2 GB` | Batas ukuran per file |

---

<div align="center">
<sub>Proyek pribadi/keluarga — semua data tetap milikmu. 🏛️</sub>
</div>
