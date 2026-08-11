-- ================================================================
-- MEDICARE - SQL SCRIPT SUPABASE
-- Untuk UKOM - Aplikasi Layanan Kesehatan
-- ================================================================
-- CARA PAKAI:
-- 1. Buka https://supabase.com/dashboard/
-- 2. Pilih project Anda (HealthTracker)
-- 3. Buka menu SQL Editor
-- 4. Copy paste SEMUA script dibawah ini, jalankan per bagian
--    (atau sekaligus juga bisa)
-- ================================================================


-- ================================================================
-- BAGIAN 1: BUAT TABEL DATABASE
-- ================================================================

-- 1a. Tabel profiles (menyimpan data user, terhubung ke auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  avatar_url TEXT,
  phone TEXT,
  gender TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);


-- 1b. Tabel doctors (data dokter)
CREATE TABLE IF NOT EXISTS doctors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  specialty TEXT NOT NULL,
  description TEXT,
  photo_url TEXT,
  phone TEXT,
  location TEXT,
  available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);


-- 1c. Tabel doctor_schedules (jadwal praktik dokter)
CREATE TABLE IF NOT EXISTS doctor_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);


-- 1d. Tabel appointments (janji temu / booking)
CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  schedule_id UUID NOT NULL REFERENCES doctor_schedules(id) ON DELETE CASCADE,
  appointment_date DATE NOT NULL,
  status TEXT DEFAULT 'pending', -- pending / confirmed / checked_in / completed / cancelled
  created_at TIMESTAMPTZ DEFAULT now()
);


-- ================================================================
-- BAGIAN 2: INSERT DATA CONTOH (SEED DATA)
-- Jalankan ini jika ingin ada data dokter & jadwal untuk demo
-- ================================================================

-- 2a. Data Dokter contoh
INSERT INTO doctors (name, specialty, description, photo_url, phone, location, available)
VALUES
  ('Dr. Ahmad Wijaya', 'Spesialis Penyakit Dalam', 'Dokter spesialis penyakit dalam dengan pengalaman lebih dari 15 tahun. Ahli menangani penyakit kronis seperti diabetes, hipertensi, dan penyakit jantung.', 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&q=80', '021-5550101', 'Klinik MediCare Lt. 1', true),
  ('Dr. Sarah Permata', 'Spesialis Anak', 'Dokter spesialis anak yang ramah dan menyayangi anak-anak. Memiliki pengalaman menangani pertumbuhan dan perkembangan anak.', 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&q=80', '021-5550102', 'Klinik MediCare Lt. 2', true),
  ('Dr. Budi Hartono', 'Spesialis Jantung', 'Dokter spesialis jantung dan pembuluh darah. Berpengalaman dalam penanganan penyakit jantung koroner dan hipertensi.', 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400&q=80', '021-5550103', 'Klinik MediCare Lt. 3', true),
  ('Dr. Maya Sari', 'Spesialis Mata', 'Dokter spesialis mata dengan keahlian di bidang katarak, minus, dan perawatan mata umum.', 'https://images.unsplash.com/photo-1651008376811-b90baee60c1f?w=400&q=80', '021-5550104', 'Klinik MediCare Lt. 2', true),
  ('Dr. Riza Kusuma', 'Dokter Umum', 'Dokter umum yang siap melayani pemeriksaan kesehatan rutin dan konsultasi medis umum.', 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&q=80', '021-5550105', 'Klinik MediCare Lt. 1', true)
ON CONFLICT DO NOTHING;


-- 2b. Data Jadwal Dokter contoh (untuk 7 hari kedepan)
INSERT INTO doctor_schedules (doctor_id, date, start_time, end_time, available)
SELECT
  d.id,
  (CURRENT_DATE + series.offset)::DATE,
  CASE series.day_slot
    WHEN 1 THEN '08:00:00'::TIME
    WHEN 2 THEN '10:00:00'::TIME
    WHEN 3 THEN '13:00:00'::TIME
    WHEN 4 THEN '15:00:00'::TIME
  END,
  CASE series.day_slot
    WHEN 1 THEN '09:30:00'::TIME
    WHEN 2 THEN '11:30:00'::TIME
    WHEN 3 THEN '14:30:00'::TIME
    WHEN 4 THEN '16:30:00'::TIME
  END,
  true
FROM doctors d
CROSS JOIN (
  SELECT
    generate_series AS offset,
    (generate_series % 4) + 1 AS day_slot
  FROM generate_series(0, 6)
) series
ON CONFLICT DO NOTHING;


-- ================================================================
-- BAGIAN 3: ROW LEVEL SECURITY (RLS) - KEAMANAN DATA
-- ================================================================
-- AKTIFKAN RLS di setiap tabel agar user HANYA bisa akses data miliknya

-- 3a. Aktifkan RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_schedules ENABLE ROW LEVEL SECURITY;


-- 3b. POLICY UNTUK TABEL profiles
-- User HANYA bisa melihat dan mengubah profile MILIKNYA SENDIRI
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);


-- 3c. POLICY UNTUK TABEL appointments
-- User HANYA bisa melihat, membuat, mengubah, dan menghapus appointment MILIKNYA
DROP POLICY IF EXISTS "Users can view own appointments" ON appointments;
CREATE POLICY "Users can view own appointments" ON appointments
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own appointments" ON appointments;
CREATE POLICY "Users can create own appointments" ON appointments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own appointments" ON appointments;
CREATE POLICY "Users can update own appointments" ON appointments
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own appointments" ON appointments;
CREATE POLICY "Users can delete own appointments" ON appointments
  FOR DELETE
  USING (auth.uid() = user_id);


-- 3d. POLICY UNTUK TABEL doctors & doctor_schedules
-- Semua user yang LOGIN bisa membaca data dokter & jadwal (READ ONLY)
DROP POLICY IF EXISTS "Authenticated users can view doctors" ON doctors;
CREATE POLICY "Authenticated users can view doctors" ON doctors
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can view schedules" ON doctor_schedules;
CREATE POLICY "Authenticated users can view schedules" ON doctor_schedules
  FOR SELECT
  USING (auth.role() = 'authenticated');


-- ================================================================
-- BAGIAN 4: STORAGE BUCKET UNTUK FOTO PROFILE (AVATARS)
-- ================================================================
-- Jalankan ini untuk membuat bucket "avatars"
-- ATAU buat manual di menu Storage > New Bucket > nama: "avatars"

-- Buat bucket (jika belum ada)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Policy untuk Storage:
-- User hanya bisa upload/lihat avatar di folder user_id nya sendiri

-- Read: semua orang bisa lihat avatar (karena bucket public)
DROP POLICY IF EXISTS "Avatar is publicly accessible" ON storage.objects;
CREATE POLICY "Avatar is publicly accessible" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'avatars');

-- Insert: user hanya bisa upload ke folder user_id nya
DROP POLICY IF EXISTS "User can upload own avatar" ON storage.objects;
CREATE POLICY "User can upload own avatar" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Update: user hanya bisa update avatar miliknya
DROP POLICY IF EXISTS "User can update own avatar" ON storage.objects;
CREATE POLICY "User can update own avatar" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );

-- Delete: user hanya bisa hapus avatar miliknya
DROP POLICY IF EXISTS "User can delete own avatar" ON storage.objects;
CREATE POLICY "User can delete own avatar" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::TEXT
  );


-- ================================================================
-- BAGIAN 5: TRIGGER - OTOMATIS BUAT PROFILE BARU SAAT USER SIGNUP
-- ================================================================
-- Agar saat user register via Supabase Auth, otomatis dibuatkan row di tabel profiles

-- Buat function handle
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'Pengguna'),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger jika sudah ada
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Buat trigger baru
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ================================================================
-- SELESAI!
-- ================================================================
-- Langkah selanjutnya di Supabase Dashboard:
--
-- 1. Authentication > URL Configuration
--    Site URL: http://localhost:3000 (bisa kosong / default)
--    Redirect URLs: tambahkan jika perlu
--
-- 2. Authentication > Providers
--    Pastikan Email provider AKTIF (default sudah aktif)
--    Disable "Confirm email" (agar lebih mudah demo UKOM)
--    Caranya: Providers > Email > toggle OFF "Confirm email"
--
-- 3. Storage > Buckets
--    Pastikan bucket "avatars" sudah ada dan bersifat Public
--
-- 4. Untuk test di aplikasi:
--    - Register user baru
--    - Login dengan user tersebut
--    - Coba fitur CRUD appointment di menu Jadwal
--    - Coba upload foto profile di menu Profile
--    - Coba Scan QR
-- ================================================================
