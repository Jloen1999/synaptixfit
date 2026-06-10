-- ============================================================================
-- Migración 0016: Plan Semanal v2 — Entregas/Exámenes + Timeline Unificado
-- ============================================================================
-- Cambios:
--   1. Nueva tabla entregas_examenes para fechas límite
--   2. Extensión de horarios_academicos con tipo_actividad, rutina_id, temas
--   3. RLS para la nueva tabla
-- ============================================================================

-- 1. Nueva tabla: entregas_examenes -------------------------------------------
CREATE TABLE IF NOT EXISTS public.entregas_examenes (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  asignatura_id   UUID REFERENCES public.asignaturas(id) ON DELETE SET NULL,
  titulo          TEXT NOT NULL,
  tipo            TEXT NOT NULL CHECK (tipo IN ('examen','entrega','presentacion','otro')),
  fecha_limite    TIMESTAMPTZ NOT NULL,
  dificultad      TEXT NOT NULL DEFAULT 'media' CHECK (dificultad IN ('baja','media','alta')),
  esta_completado BOOLEAN NOT NULL DEFAULT false,
  plan_estudio_id UUID REFERENCES public.planes_estudio(id) ON DELETE SET NULL,
  creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_entregas_examenes_usuario
  ON public.entregas_examenes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_entregas_examenes_plan
  ON public.entregas_examenes(plan_estudio_id);
CREATE INDEX IF NOT EXISTS idx_entregas_examenes_fecha
  ON public.entregas_examenes(fecha_limite);

-- 2. Extensión de horarios_academicos -----------------------------------------
ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS tipo_actividad TEXT NOT NULL DEFAULT 'estudio'
      CHECK (tipo_actividad IN ('clase','estudio','deporte','otro'));

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS rutina_id UUID REFERENCES public.rutinas(id) ON DELETE SET NULL;

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS temas TEXT;

-- Índice para filtrado por tipo_actividad
CREATE INDEX IF NOT EXISTS idx_horarios_academicos_tipo
  ON public.horarios_academicos(tipo_actividad);

-- 3. RLS para entregas_examenes -----------------------------------------------
ALTER TABLE public.entregas_examenes ENABLE ROW LEVEL SECURITY;

-- Owner full access
DROP POLICY IF EXISTS "Owner full access" ON public.entregas_examenes;
CREATE POLICY "Owner full access" ON public.entregas_examenes
  FOR ALL
  USING (auth.uid() = usuario_id)
  WITH CHECK (auth.uid() = usuario_id);

-- Lectura pública si el plan asociado es público (amigos ven)
DROP POLICY IF EXISTS "Read public via plan" ON public.entregas_examenes;
CREATE POLICY "Read public via plan" ON public.entregas_examenes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.planes_estudio p
      WHERE p.id = entregas_examenes.plan_estudio_id
        AND p.visibilidad = 'publico'
    )
  );
