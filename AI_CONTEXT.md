# MediCare Flutter - AI CONTEXT

## PROJECT

Nama aplikasi: MediCare
Framework: Flutter
Backend: Supabase
Database: PostgreSQL melalui Supabase

## FITUR YANG SUDAH ADA

- Login
- Register
- Home
- Doctor
- Doctor Detail
- Schedule
- Appointment
- Profile
- Map
- GPS
- Scan QR
- Supabase integration

## STRUKTUR DATA UTAMA

Supabase digunakan untuk:

- Authentication
- PostgreSQL Database
- Storage

Tabel utama:

- profiles
- doctors
- schedules
- appointments
- health_facilities

## APPOINTMENT

Alur:
User memilih dokter
→ memilih jadwal
→ membuat appointment
→ data disimpan ke Supabase
→ appointment memiliki ID dari Supabase

## QR CODE

Target fitur:
Setelah appointment berhasil:

1. Ambil appointment.id
2. Generate QR otomatis
3. QR berisi:
   MEDICARE-{appointment_id}
4. Tampilkan QR kepada user
5. User dapat download QR sebagai PNG
6. QR dapat digunakan oleh ScanQRPage

Jangan membuat QR melalui website eksternal.

## MAP

Map menggunakan GPS.
Lokasi fasilitas kesehatan berasal dari Supabase.
Target utama: Puskesmas di Pangkalpinang.

## ATURAN PENTING

- Jangan membuat project baru.
- Jangan menghapus fitur yang sudah berjalan.
- Jangan mengubah database tanpa alasan.
- Gunakan struktur kode yang sudah ada.
- Sebelum mengedit, baca file terkait terlebih dahulu.
- Pertahankan UI MediCare.
- Jangan membuat duplicate service/model/page.
- Setelah perubahan, jalankan flutter analyze.
- Perbaiki error compile sebelum selesai.

## STATUS TERAKHIR

Sedang mengembangkan:
Appointment → QR otomatis → Download QR.

## CARA KERJA QR

Appointment berhasil
→ appointment.id
→ "MEDICARE-{appointment.id}"
→ Flutter generate QR
→ QR ditampilkan
→ Download PNG

## JIKA MELANJUTKAN PROJECT

Pertama:

1. Baca AI_CONTEXT.md
2. Periksa struktur project
3. Cari implementasi appointment yang sudah ada
4. Jangan membuat implementasi baru sebelum memahami kode yang ada.
