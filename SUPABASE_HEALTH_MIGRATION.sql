-- ============================================================
-- SQL MIGRATION: TABEL catatan_kesehatan + RLS + FK
-- MediCare / HealthTracker - UKOM
-- ============================================================
-- JALANKAN DI SUPABASE SQL EDITOR:
-- Dashboard > SQL Editor > New Query > Paste > Run
-- ============================================================

-- ------------------------------------------------------------
-- LANGKAH 1: JIKA TABEL BELUM ADA, BUAT TABELNYA
-- (Komentari bagian ini jika tabel sudah ada)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.catatan_kesehatan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
  berat NUMERIC NOT NULL,
  tekanan_darah TEXT NOT NULL,
  detak_jantung INTEGER NOT NULL,
  catatan TEXT,
  foto_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- LANGKAH 2: JIKA TABEL SUDAH ADA TAPI user_id TIPE int8,
--    DAN TABEL KOSONG, UBAH TIPE user_id dan id JADI UUID
-- (GUNAKAN INI JIKA TABEL ADA user_id int8 / id int8)
-- ------------------------------------------------------------
-- OPSI A: Jika tabel KOSONG (data tidak penting):
-- ALTER TABLE public.catatan_kesehatan
--   ALTER COLUMN user_id TYPE UUID USING user_id::TEXT::UUID,
--   ALTER COLUMN user_id SET NOT NULL;
--
-- ALTER TABLE public.catatan_kesehatan
--   ALTER COLUMN id TYPE UUID USING gen_random_uuid(),
--   ALTER COLUMN id SET DEFAULT gen_random_uuid();
--
-- ALTER TABLE public.catatan_kesehatan
--   ALTER COLUMN tanggal SET DEFAULT CURRENT_DATE,
--   ALTER COLUMN created_at SET DEFAULT now();
--
-- ALTER TABLE public.catatan_kesehatan
--   ALTER COLUMN tanggal SET NOT NULL,
--   ALTER COLUMN berat SET NOT NULL,
--   ALTER COLUMN tekanan_darah SET NOT NULL,
--   ALTER COLUMN detak_jantung SET NOT NULL;

-- ------------------------------------------------------------
-- OPSI B: Jika ada data user_id INT8 (SIMPAN DATA LAIN):
-- (Backup dlu sebelum pakai ini)
-- ALTER TABLE public.catatan_kesehatan DROP CONSTRAINT IF EXISTS catatan_kesehatan_pkey;
-- ALTER TABLE public.catatan_kesehatan DROP COLUMN IF EXISTS id;
-- ALTER TABLE public.catatan_kesehatan ADD COLUMN id UUID PRIMARY KEY DEFAULT gen_random_uuid();
-- ALTER TABLE public.catatan_kesehatan DROP COLUMN IF EXISTS user_id;
-- ALTER TABLE public.catatan_kesehatan ADD COLUMN user_id UUID NOT NULL;
-- ALTER TABLE public.catatan_kesehatan
--   ALTER COLUMN tanggal SET DEFAULT CURRENT_DATE,
--   ALTER COLUMN created_at SET DEFAULT now();

-- ------------------------------------------------------------
-- LANGKAH 3: FOREIGN KEY KE auth.users (AKTIFKAN JIKA PERLU)
-- ------------------------------------------------------------
ALTER TABLE public.catatan_kesehatan
  DROP CONSTRAINT IF EXISTS catatan_kesehatan_user_id_fkey;

ALTER TABLE public.catatan_kesehatan
  ADD CONSTRAINT catatan_kesehatan_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- ------------------------------------------------------------
-- LANGKAH 4: INDEX UNTUK PERFORMA
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_catatan_kesehatan_user_id
  ON public.catatan_kesehatan(user_id);

CREATE INDEX IF NOT EXISTS idx_catatan_kesehatan_tanggal
  ON public.catatan_kesehatan(tanggal DESC);

CREATE INDEX IF NOT EXISTS idx_catatan_kesehatan_created
  ON public.catatan_kesehatan(created_at DESC);

-- ------------------------------------------------------------
-- LANGKAH 5: AKTIFKAN ROW LEVEL SECURITY
-- ------------------------------------------------------------
ALTER TABLE public.catatan_kesehatan ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- LANGKAH 6: RLS POLICY - HANYA BISA AKSES DATA MILIK SENDIRI
-- ------------------------------------------------------------

-- POLICY SELECT: User hanya bisa lihat data miliknya
DROP POLICY IF EXISTS "catatan_kesehatan_select_own" ON public.catatan_kesehatan;
CREATE POLICY "catatan_kesehatan_select_own" ON public.catatan_kesehatan
  FOR SELECT
  USING (auth.uid() = user_id);

-- POLICY INSERT: User hanya bisa insert data dengan user_id miliknya
DROP POLICY IF EXISTS "catatan_kesehatan_insert_own" ON public.catatan_kesehatan;
CREATE POLICY "catatan_kesehatan_insert_own" ON public.catatan_kesehatan
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- POLICY UPDATE: User hanya bisa update data miliknya
DROP POLICY IF EXISTS "catatan_kesehatan_update_own" ON public.catatan_kesehatan;
CREATE POLICY "catatan_kesehatan_update_own" ON public.catatan_kesehatan
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- POLICY DELETE: User hanya bisa hapus data miliknya
DROP POLICY IF EXISTS "catatan_kesehatan_delete_own" ON public.catatan_kesehatan;
CREATE POLICY "catatan_kesehatan_delete_own" ON public.catatan_kesehatan
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- SUPABASE STORAGE: (OPSIONAL) Jika ingin upload foto catatan
-- ============================================================
-- 1. Di Supabase Dashboard > Storage > New Bucket
--    Nama: catatan_kesehatan
--    Jenis: Private
-- 2. Atur Policy Storage (jika ingin pakai foto_url)
-- ============================================================

-- ============================================================
-- VERIFIKASI: Jalankan ini untuk cek struktur
-- ============================================================
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'catatan_kesehatan'
-- ORDER BY ordinal_position;
--
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'catatan_kesehatan';
