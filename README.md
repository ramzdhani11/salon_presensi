# Aplikasi Presensi Pegawai Salon Berbasis GPS
## Ujikom - Flutter (Dart)

---

## Struktur Project

```
lib/
├── main.dart                          # Entry point + Theme
├── models/
│   ├── user_model.dart                # Model data user
│   └── presensi_model.dart            # Model data presensi
├── services/
│   ├── database_helper.dart           # SQLite database (CRUD)
│   └── location_service.dart          # GPS & validasi radius
└── screens/
    ├── splash_screen.dart             # Splash + cek session
    ├── login_screen.dart              # Halaman login
    ├── pegawai/
    │   ├── dashboard_pegawai.dart     # Dashboard + check-in/out
    │   ├── histori_presensi.dart      # Riwayat & jam kerja
    │   └── edit_profil_pegawai.dart   # Edit profil pegawai
    └── admin/
        ├── dashboard_admin.dart       # Dashboard admin
        ├── kelola_pegawai.dart        # CRUD pegawai
        ├── atur_lokasi.dart           # Setting GPS salon
        └── laporan_presensi.dart      # Laporan harian
```

---

## Cara Menjalankan

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Izin di AndroidManifest.xml
Tambahkan di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

### 3. Jalankan
```bash
flutter run
```

---

## Akun Demo (sudah otomatis dibuat)

| Role   | Email               | Password    |
|--------|---------------------|-------------|
| Admin  | admin@salon.com     | admin123    |
| Pegawai | siti@salon.com     | pegawai123  |
| Pegawai | budi@salon.com     | pegawai123  |

---

## Fitur Lengkap

### Pegawai (User)
- Login & logout
- Dashboard: status kehadiran hari ini
- Check-in dengan validasi GPS (harus dalam radius salon)
- Check-out otomatis hitung total jam kerja
- Status otomatis: Hadir / Terlambat (jika setelah 08:30)
- Histori presensi 60 hari terakhir
- Edit profil (nama, HP, jabatan)

### Admin (Pemilik Salon)
- Login & logout
- Dashboard: rekap kehadiran semua pegawai hari ini
- Kelola pegawai: tambah, edit, hapus
- Atur lokasi GPS salon + radius (10–500 meter)
- Gunakan lokasi saat ini untuk set koordinat salon
- Laporan presensi per tanggal dengan filter kalender

---

## Database (SQLite Lokal)

### Tabel users
| Kolom       | Tipe    | Keterangan         |
|-------------|---------|--------------------|
| id          | INTEGER | Primary key        |
| nama        | TEXT    | Nama lengkap       |
| email       | TEXT    | Email (unique)     |
| password    | TEXT    | Password           |
| role        | TEXT    | admin / pegawai    |
| no_hp       | TEXT    | Nomor HP           |
| foto_profil | TEXT    | Path foto          |
| jabatan     | TEXT    | Jabatan pegawai    |

### Tabel presensi
| Kolom      | Tipe    | Keterangan           |
|------------|---------|----------------------|
| id         | INTEGER | Primary key          |
| user_id    | INTEGER | FK ke users          |
| tanggal    | TEXT    | Format YYYY-MM-DD    |
| jam_masuk  | TEXT    | Format HH:mm         |
| jam_keluar | TEXT    | Format HH:mm         |
| lat_masuk  | REAL    | Latitude GPS         |
| lng_masuk  | REAL    | Longitude GPS        |
| status     | TEXT    | hadir/terlambat      |

### Tabel lokasi_salon
| Kolom        | Tipe  | Keterangan        |
|--------------|-------|-------------------|
| nama_salon   | TEXT  | Nama salon        |
| latitude     | REAL  | Koordinat GPS     |
| longitude    | REAL  | Koordinat GPS     |
| radius_meter | REAL  | Radius area (m)   |

---

## Logika GPS

1. Pegawai tap Check-In
2. Aplikasi minta izin lokasi
3. Dapatkan koordinat GPS pegawai (geolocator)
4. Ambil koordinat salon dari database
5. Hitung jarak dengan rumus Haversine
6. Jika jarak ≤ radius → Check-In berhasil
7. Jika jarak > radius → Ditolak, tampil notifikasi jarak
