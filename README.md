# arus. / Chrysos

Prototype Flutter pemindai struk berdasarkan referensi desain. Fokus versi ini adalah tampilan dan animasi; OCR dan unggah foto belum terhubung.

## Coba preview

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\preview.ps1
```

Buka **http://127.0.0.1:4173**. Perlu Flutter SDK dan Node.js. Script dapat menemukan SDK dari konfigurasi project ketika Flutter belum ada di PATH. Setelah pernah di-build, cukup jalankan `node tool/preview-server.mjs`.

Port `4173` menyajikan hasil build statis. Build ulang untuk menampilkan perubahan kode di alamat tersebut.

Untuk hot reload, pilih Chrome sebagai device di VS Code, lalu mulai sesi debug dengan `F5`. Pengaturan workspace memicu hot reload saat file Dart disimpan. Kalau menjalankan `flutter run -d chrome` langsung dari terminal, tekan `r` untuk hot reload atau `R` untuk hot restart.

Widget preview `Chrysos — arus. receipt scan` juga tersedia dari anotasi `@Preview` di `lib/main.dart`.

## Alur demo

1. Tekan **Pindai bukti ini**.
2. Empat ikon berpindah dari barisan ke orbit sambil melewati tahap membaca dan mengidentifikasi.
3. Ikon mengecil, membulat, dan menyatu menjadi centang hijau. Kartu berubah menjadi hasil **Rp 35.000**, Warung Bu Prapto, kategori makan dan minuman.
4. **Pindai lagi** mengembalikan posisi awal. Struk contoh yang sama tidak menggandakan riwayat.
5. **Riwayat** menampilkan transaksi contoh yang selesai dipindai. Ketuk transaksi untuk membuka hasilnya.
6. **Atur** menyediakan tema gelap/terang dan animasi singkat. Preferensi pengurangan animasi sistem juga dihormati.

Durasi animasi penuh 6,2 detik, atau 0,7 detik saat animasi dikurangi. Semua data hanya di memori sesi; refresh memulai ulang demo. Tidak ada backend, koneksi API, kamera, atau penyimpanan permanen dalam versi ini.

## Struktur dan verifikasi

- `lib/main.dart`: layar scan, hasil, riwayat, pengaturan, dan tema.
- `lib/orbital_scan.dart`: timeline orbit, morph, dan penggambaran centang.
- `assets/fonts`: Roboto lokal dengan lisensi Apache 2.0; preview tidak memerlukan Google Fonts.
- `test/widget_test.dart`: alur scan dan replay, pencegahan duplikat, pengaturan, perpindahan tab, serta layout mobile/desktop.

```powershell
flutter test
dart analyze lib test
flutter build web --no-web-resources-cdn --no-wasm-dry-run
```

Build web menyertakan CanvasKit lokal agar rendering tidak bergantung pada CDN.
