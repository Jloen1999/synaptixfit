-- =============================================================================
-- Migración 20260618000022: Lienzo Continuo — Ampliación de tablas existentes
-- Refactor Time-Blocking v8.0
-- NO se crean tablas nuevas. Se amplían las existentes.
-- =============================================================================

-- 1. Ampliar CHECK de tipo_actividad en horarios_academicos
ALTER TABLE public.horarios_academicos
  DROP CONSTRAINT IF EXISTS ck_horarios_tipo_actividad;

ALTER TABLE public.horarios_academicos
  ADD CONSTRAINT ck_horarios_tipo_actividad
  CHECK (tipo_actividad = ANY (ARRAY[
    'estudio', 'deporte', 'clase', 'descanso', 'comida',
    'sueno', 'examen', 'entrega'
  ]));

-- 2. FK a entregas_examenes (vincular bloques de estudio con exámenes/entregas)
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS entrega_examen_id UUID
  REFERENCES public.entregas_examenes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_horarios_entrega_examen
  ON public.horarios_academicos(entrega_examen_id)
  WHERE entrega_examen_id IS NOT NULL;

-- 3. Nuevas columnas en entregas_examenes
ALTER TABLE public.entregas_examenes
  ADD COLUMN IF NOT EXISTS descripcion TEXT;

ALTER TABLE public.entregas_examenes
  ADD COLUMN IF NOT EXISTS hora_inicio_str TEXT;

-- 4. Ampliar CHECK de tipo en entregas_examenes
ALTER TABLE public.entregas_examenes
  DROP CONSTRAINT IF EXISTS ck_entregas_tipo;

ALTER TABLE public.entregas_examenes
  ADD CONSTRAINT ck_entregas_tipo
  CHECK (tipo = ANY (ARRAY['entrega', 'examen', 'proyecto', 'quiz', 'presentacion', 'otro']));

-- 5. Índice para queries por rango de fechas (scroll semanal)
CREATE INDEX IF NOT EXISTS idx_horarios_fecha_inicio
  ON public.horarios_academicos(usuario_id, hora_inicio);
