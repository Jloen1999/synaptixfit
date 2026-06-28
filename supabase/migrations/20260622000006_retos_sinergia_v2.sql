-- Retos v2 — Fase 1: arquitectura de datos para la sinergia académica,
-- el sistema de dificultad → XP y el deep-linking con la agenda.
--
-- Aditiva y segura (columnas nullables + defaults). No toca datos existentes.
--   * asignatura_id          → vinculación académica (etiqueta) de reto/tarea.
--   * dificultad             → 'baja' | 'media' | 'alta' (el sistema la traduce a XP).
--   * entidad_vinculada_id   → id del Examen/Entrega real de la agenda al que se ata.
--   * entidad_vinculada_tipo → 'examen' | 'entrega'.

BEGIN;

-- ── retos ──
ALTER TABLE public.retos
  ADD COLUMN IF NOT EXISTS asignatura_id uuid,
  ADD COLUMN IF NOT EXISTS dificultad text NOT NULL DEFAULT 'media',
  ADD COLUMN IF NOT EXISTS entidad_vinculada_id uuid,
  ADD COLUMN IF NOT EXISTS entidad_vinculada_tipo text;

ALTER TABLE public.retos DROP CONSTRAINT IF EXISTS ck_retos_dificultad;
ALTER TABLE public.retos
  ADD CONSTRAINT ck_retos_dificultad
  CHECK (dificultad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text]));

ALTER TABLE public.retos DROP CONSTRAINT IF EXISTS ck_retos_entidad_tipo;
ALTER TABLE public.retos
  ADD CONSTRAINT ck_retos_entidad_tipo
  CHECK (entidad_vinculada_tipo IS NULL
    OR entidad_vinculada_tipo = ANY (ARRAY['examen'::text, 'entrega'::text]));

-- ── hitos_de_reto (subtareas) ──
ALTER TABLE public.hitos_de_reto
  ADD COLUMN IF NOT EXISTS asignatura_id uuid,
  ADD COLUMN IF NOT EXISTS dificultad text NOT NULL DEFAULT 'media',
  ADD COLUMN IF NOT EXISTS entidad_vinculada_id uuid,
  ADD COLUMN IF NOT EXISTS entidad_vinculada_tipo text;

ALTER TABLE public.hitos_de_reto DROP CONSTRAINT IF EXISTS ck_hitos_dificultad;
ALTER TABLE public.hitos_de_reto
  ADD CONSTRAINT ck_hitos_dificultad
  CHECK (dificultad = ANY (ARRAY['baja'::text, 'media'::text, 'alta'::text]));

ALTER TABLE public.hitos_de_reto DROP CONSTRAINT IF EXISTS ck_hitos_entidad_tipo;
ALTER TABLE public.hitos_de_reto
  ADD CONSTRAINT ck_hitos_entidad_tipo
  CHECK (entidad_vinculada_tipo IS NULL
    OR entidad_vinculada_tipo = ANY (ARRAY['examen'::text, 'entrega'::text]));

-- Índices para resolver el deep-linking rápido (al completar un examen/entrega).
CREATE INDEX IF NOT EXISTS idx_retos_entidad_vinculada
  ON public.retos (entidad_vinculada_id)
  WHERE entidad_vinculada_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_hitos_entidad_vinculada
  ON public.hitos_de_reto (entidad_vinculada_id)
  WHERE entidad_vinculada_id IS NOT NULL;

COMMIT;
