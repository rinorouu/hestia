# Hestia — Mobile App (Flutter)

Client mobile untuk [Hestia](../README.md), aplikasi self-hosted photo & video storage keluarga.

> **Status:** kode Dart (`lib/`, `pubspec.yaml`) sudah ditulis lengkap, tapi folder native
> (`android/`, `ios/`) **belum digenerate** karena ditulis di lingkungan tanpa Flutter SDK.
> Ikuti langkah setup di bawah sebelum menjalankan app untuk pertama kali.

## Setup pertama kali

1. Pastikan Flutter SDK terpasang (`flutter doctor`).
2. Generate scaffold native (android/ios) tanpa menimpa `lib/` & `pubspec.yaml` yang sudah ada:
   ```bash
   cd app
   flutter create --org com.hestia --project-name hestia_app .
   ```
   Jika prompt menawarkan overwrite `pubspec.yaml`/`lib/main.dart`, **jangan overwrite** —
   pilih skip/`n`, atau backup dulu (`git stash`) lalu jalankan `flutter create .` di working
   tree bersih, baru `git stash pop` untuk mengembalikan kode yang sudah ada.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Jalankan:
   ```bash
   flutter run
   ```

## Menghubungkan ke server

Saat pertama kali dibuka, app akan meminta **alamat server** (mis. `http://192.168.1.10:3000`
untuk server Hestia di jaringan lokal). Alamat ini disimpan di perangkat dan bisa diubah lagi
lewat tab **Pengaturan**.

Jalankan backend-nya dulu — lihat [`../server`](../server).

## Struktur

```
lib/
  core/       Dio client + auth interceptor + parsing error API
  models/     Model data (User, FileItem, FolderItem, HistoryItem, StorageStatus)
  services/   ChangeNotifier: server config, auth, storage status, file, history
  screens/    Splash, server setup, login/register, browse, upload, history, settings
  widgets/    Komponen reusable (storage banner, grid tile, loading/error view)
  utils/      Formatter (ukuran file, tanggal)
```

## Cakupan saat ini

Mengikuti `../docs/MVP_CHECKLIST.md` bagian "Mobile App (Flutter)":

- [x] Setup project Flutter + struktur dasar
- [x] Login & Register
- [x] Token di secure storage + auto-login
- [x] Browse (folder, grid thumbnail, info file)
- [x] Upload foto/video (single & multiple)
- [x] Indikator "media penyimpanan tidak tersedia"
- [x] Download file ke smartphone
- [x] Riwayat upload
- [x] Pengaturan server (alamat server, logout)
- [ ] Auto Sync — **belum dikerjakan**, menyusul setelah core app teruji di device nyata.

## Verifikasi manual yang perlu dilakukan

Karena ditulis tanpa akses Flutter SDK, alur berikut belum pernah dijalankan nyata — uji end-to-end
setelah `flutter run`:

register → login → browse (root & subfolder) → upload (single & multiple, coba juga saat HDD
server dilepas untuk lihat storage banner) → buka detail file (image & video) → download →
hapus file → cek riwayat → ganti alamat server → logout → auto-login (buka app lagi).
