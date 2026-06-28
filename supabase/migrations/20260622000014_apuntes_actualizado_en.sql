-- Migration: Añade columna actualizado_en a apuntes
-- La tabla apuntes se creó sin actualizado_en en 20260616000004_consolidacion_fixes.sql,
-- pero el código (ApunteDb.fromMap, apuntesPorAsignaturaProvider, actualizarApunte)
-- depende de ella. Se añade con IF NOT EXISTS por si existe en remoto.

ALTER TABLE public.apuntes
    ADD COLUMN IF NOT EXISTS actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_apuntes_usuario_actualizado
    ON public.apuntes(usuario_id, actualizado_en DESC);
