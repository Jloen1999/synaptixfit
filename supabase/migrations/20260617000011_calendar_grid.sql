-- =============================================================================
-- Migración 20260617000011: Calendar Grid — Columnas para grid semanal
-- Sprint 1: Infraestructura Time-Blocking
-- =============================================================================

-- 1. Añadir columna es_fijo a horarios_academicos
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS es_fijo BOOLEAN NOT NULL DEFAULT false;

-- 2. Añadir columna dia_semana a horarios_academicos (1=Lunes..7=Domingo)
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS dia_semana INTEGER;

-- 3. CHECK constraint para dia_semana
ALTER TABLE public.horarios_academicos
  DROP CONSTRAINT IF EXISTS ck_horarios_dia_semana;

ALTER TABLE public.horarios_academicos
  ADD CONSTRAINT ck_horarios_dia_semana
  CHECK (dia_semana IS NULL OR (dia_semana >= 1 AND dia_semana <= 7));

-- 4. Índices para consultas rápidas por día y por tipo fijo
CREATE INDEX IF NOT EXISTS idx_horarios_dia_semana
  ON public.horarios_academicos(dia_semana);

CREATE INDEX IF NOT EXISTS idx_horarios_es_fijo
  ON public.horarios_academicos(es_fijo);

-- 5. Deducir dia_semana desde hora_inicio para datos existentes
UPDATE public.horarios_academicos
SET dia_semana = EXTRACT(ISODOW FROM hora_inicio)::INTEGER
WHERE dia_semana IS NULL
  AND hora_inicio IS NOT NULL;

-- 6. Marcar como fijos los horarios con tipo_actividad = 'clase'
UPDATE public.horarios_academicos
SET es_fijo = true
WHERE tipo_actividad = 'clase'
  AND es_fijo = false;
