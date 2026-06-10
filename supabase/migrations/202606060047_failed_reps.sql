-- =============================================================================
-- 0047: failed_reps — track failed repetitions per series
-- =============================================================================

ALTER TABLE public.series_sesion
  ADD COLUMN IF NOT EXISTS failed_reps INT NOT NULL DEFAULT 0 CHECK (failed_reps >= 0);
