<div align="center">

# 🏛️ Hestia

**Self-hosted photo & video storage**

Simpan, akses, dan kelola foto serta video dari ponsel langsung ke Hard Disk
di server pribadimu — Ini sangat sederhana, cepat, ringan, dan sepenuhnya privat.

![status](https://img.shields.io/badge/status-beta-yellow)
![backend](https://img.shields.io/badge/backend-Node.js%20%2B%20Express-green)
![mobile](https://img.shields.io/badge/mobile-Flutter-blue)
![db](https://img.shields.io/badge/db-SQLite-lightgrey)

</div>

---

## 📖 Apa itu Hestia?

**Hestia** adalah aplikasi penyimpanan foto & video yang berjalan di **server pribadi**
(mini PC, Raspberry Pi, atau home server) dan menyimpan seluruh file langsung ke
**Hard Disk eksternal** milikmu.

Tujuannya bukan meniru layanan poto cloud pada umumnya, melainkan
menyediakan solusi penyimpanan keluarga yang **privat, ringan, dan mudah digunakan**.
Setiap anggota keluarga memiliki akun sendiri, ruang penyimpanan sendiri, dan hak akses
sendiri. Seluruh data tetap berada di perangkat pribadimu — **tanpa cloud pihak ketiga.**

> Nama "Hestia" diambil dari dewi perapian & rumah dalam mitologi Yunani —
> melambangkan tempat yang aman untuk menyimpan kenangan keluarga.

---

## ✨ Fitur

- 🔐 **Registrasi & login** — akun berbasis email + password dengan autentikasi token (JWT).
- 👨‍👩‍👧‍👦 **Multi-user** — banyak akun dalam satu server, penyimpanan tiap pengguna terisolasi.
- ⬆️ **Upload dari galeri** — pilih banyak foto & video langsung dari galeri ponsel, mendukung subfolder.
- 🗂️ **Jelajah file** — telusuri folder, lihat thumbnail, ukuran, dan tanggal upload.
- 🖼️ **Thumbnail otomatis** — pratinjau gambar dibuat otomatis saat upload.
- ⬇️ **Download** — ambil kembali file dari Hard Disk ke ponsel (mendukung resume/streaming).
- 🕘 **Riwayat upload** — catatan file yang berhasil maupun gagal diunggah.
- 💽 **Deteksi HDD** — upload otomatis dinonaktifkan bila Hard Disk eksternal belum terpasang.
- 🔒 **Aman** — password di-hash, isolasi antar-pengguna, proteksi path & validasi tipe file.

---

## 🧰 Teknologi yang Digunakan

**Backend**

| Kategori | Teknologi |
|----------|-----------|
| Bahasa & Runtime | Node.js (JavaScript) |
| Web Framework | Express |
| Database | SQLite — menyimpan metadata; file asli di HDD |
| Autentikasi | JSON Web Token (JWT) + bcrypt |
| Upload File | Multer |
| Pemrosesan Gambar | Sharp (thumbnail) |
| Keamanan | express-rate-limit, anti path-traversal |

**Frontend (Mobile)**

| Kategori | Teknologi |
|----------|-----------|
| Framework | Flutter / Dart |
| HTTP Client | Dio (multipart upload + progres) |
| State Management | Provider |
| Pemilih Media | image_picker (galeri sistem) |
| Penyimpanan Token | flutter_secure_storage |

---

## 💻 System Requirements

### Server

| Komponen | Minimum | Rekomendasi |
|----------|---------|-------------|
| Sistem Operasi | Linux / Windows / macOS | Linux (mini PC / Raspberry Pi 4+) |
| Node.js | v20 atau lebih baru | v20 LTS |
| RAM | 512 MB | 1 GB atau lebih |
| Penyimpanan | HDD eksternal | HDD + HDD kedua untuk backup |
| Jaringan | LAN (jaringan lokal) | LAN; akses luar jaringan via VPN (mis. Tailscale) atau domain + HTTPS |

### Perangkat Pengguna

- Smartphone **Android**.
- Aplikasi dipasang langsung melalui file **APK**
---

## 🚀 Cara Install — Server (Backend)

### 1. Prasyarat
- [Node.js ≥ 20](https://nodejs.org/) (termasuk npm)
- [Git](https://git-scm.com/)

### 2. Ambil kode
```bash
git clone https://github.com/rinorouu/hestia.git
cd hestia/backend/server
```

### 3. Install dependencies
```bash
npm install
```

### 4. Siapkan konfigurasi
```bash
cp .env.example .env
```
Buka `.env` lalu sesuaikan. Yang penting:
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

Server berjalan di **`http://localhost:3000`**. Cek dengan membuka
`http://localhost:3000/api/health` — jika membalas `{"status":"ok"}`, server siap digunakan. 🎉

---

## 📱 Membangun Aplikasi Mobile (Frontend)

### 1. Prasyarat
- [Flutter SDK](https://flutter.dev/) + Android SDK (mis. via Android Studio)

### 2. Siapkan & build
```bash
cd hestia/frontend/app
flutter pub get
dart run flutter_launcher_icons   # (opsional) generate ikon aplikasi
flutter build apk --release
```

APK hasil build ada di:
```
build/app/outputs/flutter-apk/app-release.apk
```
Pasang di ponsel, buka aplikasi, lalu isi alamat server (mis. `http://192.168.1.10:3000`).
Ponsel harus berada di jaringan yang sama dengan server, atau terhubung melalui VPN.

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
<sub>100% privat — Momenmu adalah milikmu. 🔒</sub>
</div>
