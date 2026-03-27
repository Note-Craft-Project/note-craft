# Note Craft 🎼

**Note Craft** adalah platform interaktif modern yang dirancang untuk merevolusi cara belajar musik melalui pendekatan *game-based learning*. Proyek ini terdiri dari aplikasi mobile (Flutter) dan backend server (Elysia + Bun). 

Dikembangkan di bawah naungan **PT Bina Talenta Kursus Musik**, Note Craft hadir sebagai solusi atas tantangan tradisional dalam mempelajari teori musik, menjadikannya lebih menyenangkan, terstruktur, dan mudah diakses oleh siapa saja.

---

## 🎯 Visi & Misi

- **Visi**: Menjadi platform pendidikan musik terdepan yang membantu jutaan siswa membaca dan memahami musik dengan percaya diri.
- **Misi**: Mengubah metode pembelajaran musik yang konvensional menjadi pengalaman interaktif yang memotivasi siswa melalui teknologi AI dan umpan balik real-time.

---

## 📂 Struktur Proyek

- `mobile/`: Aplikasi mobile berbasis Flutter.
- `backend/`: API Backend menggunakan ElysiaJS & Bun.

---

## 🚀 Fitur Utama

- **Latihan Ritme Interaktif**: Menggunakan input ketukan, tepukan tangan, dan deteksi mikrofon untuk melatih kepekaan tempo.
- **AI Feedback System**: Umpan balik langsung (Perfect, Good, Miss) berdasarkan algoritma pendeteksi ketepatan waktu.
- **Peta Jalan Kurikulum**:
  - `Level 1`: Pelatihan Ritme (Fokus saat ini).
  - `Level 2`: Pengenalan Notasi Musik.
  - `Level 3`: Integrasi Ritme & Pitch.
  - `Level 4`: Latihan Membaca Partitur Lengkap.
  - `Level 5`: Bermain Lagu dengan Instrumen Asli.

---

## 🏗️ Tim Proyek

| Peran | Nama |
| :--- | :--- |
| **Owner (PT Bina Talenta)** | **Prasetya Rizky Purnama** |
| **UI/UX Designer** | **Ruth Septriana Sipangkar** |
| **Lead Developer** | **Syafiq Abiyyu Taqi** |

---

## 🛠️ Tech Stack

### **Frontend & Mobile**
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio) & [record](https://pub.dev/packages/record)

### **Backend & Infrastructure**
- **Runtime**: [Bun](https://bun.sh/)
- **Framework**: [ElysiaJS](https://elysiajs.com/)
- **Language**: [TypeScript](https://www.typescriptlang.org/)

---

## 📥 Panduan Memulai

### **Backend**
1. Masuk ke direktori `backend/`.
2. Jalankan `bun install`.
3. Mulai server dengan `bun dev`.
4. Dokumentasi API tersedia di `http://localhost:3000/swagger`.

### **Mobile**
1. Masuk ke direktori `mobile/`.
2. Jalankan `flutter pub get`.
3. Jalankan aplikasi dengan `flutter run`.
4. Untuk build rilis: `flutter build apk --release --split-per-abi`.

---

## 📅 Status Pengembangan

**Versi v0.1.0 (Initial Pre-Release)**
- Implementasi inti sistem ritme Level 1.
- Sinkronisasi audio-visual dasar.
- Desain antarmuka imersif tahap awal.

---

© 2026 **PT Bina Talenta Kursus Musik**.
