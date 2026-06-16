# GitTrace

> *"Trace every commit, report every day."*

**GitTrace** adalah aplikasi Flutter Desktop (Windows, macOS, Linux) yang dirancang khusus untuk mempermudah mahasiswa magang atau pekerja dalam membuat laporan bulanan berbasis aktivitas Git lokal. Aplikasi ini mendeteksi aktivitas Git Anda, memvisualisasikannya ke dalam kalender bulanan interaktif, mengizinkan penyesuaian jam kerja dan kegiatan, serta menghasilkan laporan terformat secara otomatis.

---

## 🚀 Fitur Utama

### 1. Kalender Aktivitas Git (Dashboard Utama)
Aplikasi memindai repositori Git lokal Anda secara rekursif dan menyusun riwayat commit ke dalam kalender bulanan yang interaktif. Anda dapat melihat seberapa produktif hari-hari Anda dengan statistik commit harian, jumlah hari aktif, dan jumlah repositori yang berkontribusi.

![Dashboard Kalender Utama](docs/home.png)

* **Repository Scanner & Selector**: Pilih folder utama pekerjaan Anda, dan GitTrace akan mendeteksi seluruh repositori Git di dalamnya secara otomatis. Anda dapat memfilter repositori mana saja yang ingin disertakan dalam laporan melalui sidebar kiri.
* **Warna Repositori Khusus**: Setiap repositori mendapatkan penanda warna unik untuk membedakan aktivitas antar project dengan mudah di kalender.
* **Indikator Statistik**: Menampilkan jumlah total commit, hari aktif kerja, repositori terpilih, dan jam kerja yang telah diinput.

---

### 2. Pengaturan Jam Kerja (Working Hours)
Laporan magang umumnya memerlukan pencatatan jam masuk dan jam pulang. GitTrace memudahkan pengisian ini:
* **Pengaturan Jam Kerja Harian**: Cukup klik tanggal tertentu di kalender untuk menyesuaikan jam masuk dan jam pulang.
* **Bulk Set Jam Kerja**: Fitur pengisian sekaligus untuk rentang tanggal tertentu agar Anda tidak perlu mengisi satu per satu secara manual.

---

### 3. Pratinjau & Edit Kegiatan (Draft Auto-Save)
Sebelum berkas laporan diunduh, Anda dapat meninjau data dalam bentuk tabel pratinjau yang rapi.
* **Edit Teks Kegiatan**: Anda dapat mengedit teks deskripsi kegiatan hari apa pun secara langsung pada kotak teks pratinjau.
* **Auto-Save Draft (Persistensi Data)**: Perubahan teks kegiatan yang Anda edit akan otomatis tersimpan ke penyimpanan lokal secara real-time. Data draf Anda aman dan tidak akan hilang meskipun aplikasi ditutup/dimatikan.
* **Reset Per Baris & Global**: Menyediakan tombol untuk mereset kegiatan di baris tertentu atau secara global kembali ke teks default commit Git asli.

---

### 4. Ekspor Laporan Multiformat (Excel, Word & PDF)
Format laporan yang dihasilkan telah disesuaikan dengan standar umum laporan magang.

![Pratinjau Ekspor Laporan](docs/export.png)

* **Ekspor Excel (.xlsx)**:
  * Dilengkapi kolom Hari/Tanggal, Jam Masuk, Jam Pulang, dan Kegiatan.
  * Fitur *Auto-width* dan *Text Wrap* agar dokumen langsung rapi saat dicetak.
* **Ekspor Word (.docx) dengan Template Kustom**:
  * Mendukung penggunaan template dokumen Word dari kampus/instansi Anda sendiri.
  * Variabel khusus seperti `{{nama}}`, `{{nim}}`, `{{prodi}}`, `{{mitra}}`, `{{hari_tanggal}}`, `{{jam_masuk}}`, `{{jam_pulang}}`, dan `{{kegiatan}}` akan disubstitusi secara otomatis ke dalam dokumen.
  * **Keep-Together Layout**: Secara otomatis mengamankan blok tanda tangan mahasiswa & dosen pembimbing di halaman yang sama agar tidak terpisah di batas halaman.
* **Ekspor PDF (.pdf) Presisi**:
  * **Native PDF (A4 & 1-Inch Margins)**: Menghasilkan berkas PDF yang rapi, presisi, bersih, dan sesuai standar Google Docs.
  * **LibreOffice Fallback**: Otomatis menggunakan konversi headless LibreOffice jika pengguna menggunakan file template Word kustom.

---

### 5. Penanganan Commit Duplikat (Duplicate Commit Resolver)
Jika terdapat commit yang memiliki deskripsi pesan yang serupa pada hari yang sama (misalnya akibat aktivitas *rebase*, *cherry-pick*, atau commit yang tidak sengaja terduplikasi di repo berbeda):
* **Gabung (Merge)**: Menyatukan pesan commit yang sama menjadi satu baris deskripsi kegiatan agar laporan lebih ringkas dan profesional.
* **Pisah (Separate)**: Tetap membiarkan commit tertulis terpisah baris per baris.

---

### 6. Integrasi File Manager & Premium Dark Mode
* **Integrasi Pasca-Ekspor**: Tombol interaktif **"Buka Folder"** dan **"Buka File"** langsung muncul sesaat setelah ekspor berhasil, untuk membuka lokasi dokumen secara instan.
* **Premium Dark Mode**: Pilihan tema Dark Mode berkualitas premium yang nyaman digunakan kapan saja.

---

## 👷 Alur Kerja CI/CD (Otomatisasi Release)

Aplikasi ini dikonfigurasi menggunakan **GitHub Actions** untuk membangun aplikasi desktop secara otomatis setiap kali Anda melakukan push tag versi baru (misalnya `v2.0.0`):
* Menghasilkan binary Windows Installer (`.exe`), Windows Portable (`.zip`), dan Linux Bundle (`.tar.gz`).
* Mengunggah aset kompilasi tersebut secara otomatis ke halaman **GitHub Releases**.
* Mengelompokkan catatan rilis (*release notes*) secara cerdas berdasarkan label `Windows` dan `Linux`.

---

## 💻 Cara Menjalankan Project

### Prasyarat
* Flutter SDK (`>=3.10.0`)
* Git CLI terinstal pada sistem operasi Anda

### Langkah-langkah
1. **Clone repositori ini**:
   ```bash
   git clone https://github.com/ekyaaa/git_trace.git
   cd git_trace
   ```
2. **Unduh dependensi**:
   ```bash
   flutter pub get
   ```
3. **Jalankan aplikasi (Desktop)**:
   * **Windows**: `flutter run -d windows`
   * **macOS**: `flutter run -d macos`
   * **Linux**: `flutter run -d linux`
