-- ============================================================
-- Migración 0005: Fechas y coherencia de datos
-- Propósito: Añadir fecha_inicio a rutinas para tracking temporal
-- ============================================================

-- 1. Añadir fecha_inicio a rutinas (nullable: se setea al primer entrenamiento)
ALTER TABLE public.rutinas ADD COLUMN IF NOT EXISTS fecha_inicio DATE;

-- 2. Índice para consultas por fecha
CREATE INDEX IF NOT EXISTS idx_rutinas_fecha_inicio ON public.rutinas(usuario_id, fecha_inicio);
