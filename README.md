# Chrysos

Pemindai struk Flutter dengan OCR lokal dan preview foto sebelum pemindaian.

## Coba preview

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\preview.ps1
```

Buka **http://127.0.0.1:4173**. Perlu Flutter SDK dan Node.js. Script dapat menemukan SDK dari konfigurasi project ketika Flutter belum ada di PATH. Setelah pernah di-build, cukup jalankan `node tool/preview-server.mjs`.

Jika server `4173` sudah berjalan, jalankan `flutter build web --no-web-resources-cdn --no-wasm-dry-run` dari root project, lalu klik reload di Flex Preview.

Untuk hot reload, pilih Chrome sebagai device di VS Code, lalu mulai sesi debug dengan `F5`. Pengaturan workspace memicu hot reload saat file Dart disimpan. Kalau menjalankan `flutter run -d chrome` langsung dari terminal, tekan `r` untuk hot reload atau `R` untuk hot restart.

Widget preview `Chrysos — Scan` juga tersedia dari anotasi `@Preview` di `lib/main.dart`.

## Alur scan

1. Pilih **Upload gambar** dan buka satu JPG atau PNG hingga 15 MB.
2. Periksa foto, lalu tekan **Scan Now**. Ikon berputar selama OCR bekerja dan menyatu menjadi centang saat teks berhasil dibaca.
3. Salin teks hasil scan atau tekan **Sesi baru** untuk mengosongkan halaman Scan. Total ditampilkan jika label dan nominal terbaca dengan jelas.

**Riwayat** menampilkan hasil selama aplikasi terbuka. **Atur** menyediakan tema gelap/terang dan pengurangan gerakan. OCR berjalan di browser dengan Tesseract, di Android dengan ML Kit, dan di iOS dengan Vision. Foto diproses di perangkat.

## Struktur dan verifikasi

- `lib/main.dart`: layar scan, hasil, riwayat, pengaturan, dan tema.
- `lib/orbital_scan.dart`: orbit dan transisi centang.
- `lib/receipt_ocr.dart`: pemilih file dan ekstraksi total dari teks OCR.
- `assets/fonts`: Roboto lokal dengan lisensi Apache 2.0; preview tidak memerlukan Google Fonts.
- `test/widget_test.dart`: OCR dimulai setelah tombol ditekan, penanganan foto yang tidak terbaca, serta reset sesi scan.

```powershell
flutter test
dart analyze lib test
flutter build web --no-web-resources-cdn --no-wasm-dry-run
```

Build web menyertakan CanvasKit dan model OCR Indonesia secara lokal.
