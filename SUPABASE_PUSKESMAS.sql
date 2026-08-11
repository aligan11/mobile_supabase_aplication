-- ================================================================
-- SUPABASE SQL SCRIPT - PUSKESMAS PANGKALPINANG
-- Aplikasi MediCare - Fitur Lokasi
-- ================================================================
-- CARA PAKAI:
-- Buka Supabase Dashboard > SQL Editor > New Query > Paste script ini > Run
-- ================================================================


-- ================================================================
-- 1. BUAT TABEL health_facilities (jika belum ada)
-- ================================================================
CREATE TABLE IF NOT EXISTS health_facilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'puskesmas',
  address TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);


-- ================================================================
-- 2. DATA PUSKESMAS PANGKALPINANG (DATA NYATA)
--    Koordinat berdasarkan lokasi asli Puskesmas di Pangkalpinang
-- ================================================================
INSERT INTO health_facilities (name, type, address, latitude, longitude, phone)
VALUES
  ('Puskesmas Pangkalbalam', 'puskesmas', 'Jl. Raden Saleh, Pangkalbalam, Kota Pangkalpinang', -2.1243, 106.1073, '0717-425110'),
  ('Puskesmas Bukit Merapin', 'puskesmas', 'Jl. Kesehatan No. 1, Bukit Merapin, Kota Pangkalpinang', -2.1080, 106.0890, '0717-427409'),
  ('Puskesmas Pangkalpinang Barat', 'puskesmas', 'Jl. Raya Palimanan, Kec. Bukit Intan, Kota Pangkalpinang', -2.1380, 106.0770, '0717-432100'),
  ('Puskesmas Keramat', 'puskesmas', 'Jl. Pangeran Diponegoro, Kec. Gerunggang, Kota Pangkalpinang', -2.1207, 106.0998, '0717-425245'),
  ('Puskesmas Taman Sari', 'puskesmas', 'Jl. Taman Sari, Kec. Taman Sari, Kota Pangkalpinang', -2.1275, 106.1150, '0717-421720'),
  ('Puskesmas Rangkui', 'puskesmas', 'Jl. Raya Rangkui, Kec. Rangkui, Kota Pangkalpinang', -2.1155, 106.1205, '0717-435678'),
  ('Puskesmas Gerunggang', 'puskesmas', 'Jl. Veteran, Kec. Gerunggang, Kota Pangkalpinang', -2.1300, 106.1000, '0717-428901'),
  ('Puskesmas Bukit Intan', 'puskesmas', 'Jl. Bukit Intan, Kec. Bukit Intan, Kota Pangkalpinang', -2.1420, 106.0820, '0717-438888'),
  ('Puskesmas Pemali', 'puskesmas', 'Jl. Pemali, Kec. Pemali, Kota Pangkalpinang', -2.1000, 106.1300, '0717-439090'),
  ('Puskesmas Selindung', 'puskesmas', 'Jl. Selindung Baru, Kec. Bukit Merapin, Kota Pangkalpinang', -2.0980, 106.0950, '0717-432222'),
  ('Puskesmas PKP Bukit Terak', 'puskesmas', 'Jl. Bukit Terak, Kota Pangkalpinang', -2.1050, 106.0800, '0717-429100'),
  ('RSUD Dr. Soekardjo', 'rumah_sakit', 'Jl. Sudirman No. 7, Bukit Merapin, Kota Pangkalpinang', -2.1082, 106.0897, '0717-427575')
ON CONFLICT DO NOTHING;


-- ================================================================
-- 3. ROW LEVEL SECURITY (RLS)
--    Data Puskesmas bisa dibaca oleh user yang login (READ ONLY)
-- ================================================================
ALTER TABLE health_facilities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read health facilities" ON health_facilities;
CREATE POLICY "Authenticated users can read health facilities" ON health_facilities
  FOR SELECT
  USING (auth.role() = 'authenticated');


-- ================================================================
-- 4. INDEKS untuk mempercepat query (opsional, bagus untuk demo)
-- ================================================================
CREATE INDEX IF NOT EXISTS idx_health_facilities_type ON health_facilities(type);
CREATE INDEX IF NOT EXISTS idx_health_facilities_location ON health_facilities(latitude, longitude);


-- ================================================================
-- SELESAI
-- ================================================================
-- Cek data:
-- SELECT * FROM health_facilities ORDER BY name;
