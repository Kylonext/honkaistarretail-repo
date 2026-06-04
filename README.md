# Honkai Star Retail - Application

Aplikasi Retail bertema *Honkai Star Rail* yang dibangun menggunakan framework **Flutter** untuk sisi Client, serta terintegrasi dengan sistem otentikasi lokal dan **Google Sign-In Authentication**.

---

## 🚀 Persyaratan Sistem (Prerequisites)

Sebelum menjalankan aplikasi, pastikan perangkat kamu sudah terpasang *tools* berikut:

* **Flutter SDK** (Versi terbaru atau minimal v3.19.0)
* **Dart SDK** (Sudah include di dalam Flutter)
* **Android Studio** / **VS Code** (+ Ekstensi Flutter & Dart)

---

## 🛠️ Langkah-langkah Menjalankan Aplikasi

Ikuti urutan perintah di bawah ini melalui terminal/command prompt di dalam direktori proyek:

### 1. Clone atau Buka Folder Proyek
Pastikan terminal kamu sudah berada di dalam root directory proyek `gachamerch`:
```Bash
cd gachamerch
```

2. Unduh Dependencies (Package Fetch)
Ambil semua package pihak ketiga yang tertera di pubspec.yaml (seperti google_sign_in, http, dll):

```Bash
flutter pub get
```

3. Jalankan Aplikasi (Run App)
Jalankan aplikasi dalam mode pengembangan (Development Mode):

```Bash
flutter run -d chrome --web-port=5000
```

Tunggu sekitar 30-60 detik agar server backend bisa bootup terlebih dahulu, sampai web terbuka.

Akun dummy yang bisa digunakan apabila tidak ingin menggunakan Google Sign-In:
(Akun USER) : trailblazer
(Password USER) : trailblazer123

(Akun ADMIN) : pom-pom
(Password ADMIN) : admin123
