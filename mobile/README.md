# Note Craft 🎼

**Note Craft** adalah platform interaktif modern yang dirancang untuk merevolusi cara belajar musik melalui pendekatan *game-based learning*. Aplikasi ini berfokus pada pelatihan ritme, pembacaan notasi musik, dan praktik bermain lagu secara presisi. 

Dikembangkan di bawah naungan **PT Bina Talenta Kursus Musik**, Note Craft hadir sebagai solusi atas tantangan tradisional dalam mempelajari teori musik, menjadikannya lebih menyenangkan, terstruktur, dan mudah diakses oleh siapa saja.

---

## 🎯 Visi & Misi

- **Visi**: Menjadi platform pendidikan musik terdepan yang membantu jutaan siswa membaca dan memahami musik dengan percaya diri.
- **Misi**: Mengubah metode pembelajaran musik yang konvensional menjadi pengalaman interaktif yang memotivasi siswa melalui teknologi AI dan umpan balik real-time.

---

## 🚀 Fitur Utama (Berdasarkan Pitch Deck)

Note Craft dirancang dengan kurikulum musik yang komprehensif :

- **Latihan Ritme Interaktif**: Menggunakan input ketukan, tepukan tangan, dan deteksi mikrofon untuk melatih kepekaan tempo.
- **Pembacaan Notasi Musik**: Latihan membaca not pada paranada secara interaktif mulai dari tingkat dasar hingga mahir.
- **AI Feedback System**: Umpan balik langsung menggunakan algoritma pendeteksi ketepatan waktu (Perfect, Good, Miss) dan deteksi tinggi nada (Pitch).
- **Kurikulum Terstruktur**:
  - `Level 1`: Pelatihan Ritme (Fokus saat ini).
  - `Level 2`: Pengenalan Notasi Musik.
  - `Level 3`: Integrasi Ritme & Pitch.
  - `Level 4`: Latihan Membaca Partitur Lengkap.
  - `Level 5`: Bermain Lagu dengan Instrumen Asli.

---

## 🏗️ Tim Proyek

| Peran | Nama |
| :--- | :--- |
| **Owner (PT Bina Talenta)** | **Prasetya Rizky** |
| **UI/UX Designer** | **Ruth Septriana Sipangkar** |
| **Lead Developer** | **Syafiq Abiyyu Taqi** |

---

## 🛠️ Tech Stack

### **Frontend (Mobile)**
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio) & [record](https://pub.dev/packages/record)
- **Visuals**: [flutter_svg](https://pub.dev/packages/flutter_svg)

### **Backend**
- **Runtime**: [Bun](https://bun.sh/)
- **Framework**: [ElysiaJS](https://elysiajs.com/)
- **Language**: [TypeScript](https://www.typescriptlang.org/)

---

## 📅 Status Pengembangan

**Versi v0.1.0 (Initial Pre-Release)**
- Fokus pada `Level 1: Latihan Ritme`.
- Implementasi sistem feedback akurasi ketukan.
- Desain antarmuka imersif yang selaras dengan visi produk di Pitch Deck.

---

## 📥 Prasyarat & Instalasi

Pastikan lingkungan pengembangan Anda mendukung :
- Flutter SDK (Versi ^3.10.7)
- Android API Level 21+

```bash
# Menjalankan aplikasi
flutter run

# Membangun file rilis (Optimasi ukuran untuk distribusi)
flutter build apk --release --split-per-abi
```

---

© 2026 **PT Bina Talenta Kursus Musik**.