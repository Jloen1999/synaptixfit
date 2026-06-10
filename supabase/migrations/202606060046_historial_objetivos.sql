-- =============================================================================
-- 0046: historial_objetivos — track user objective changes for transition logic
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.historial_objetivos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  objetivo TEXT NOT NULL,
  objetivo_anterior TEXT,
  fecha_inicio DATE NOT NULL DEFAULT current_date,
  fecha_fin DATE,
  rutina_ids UUID[] DEFAULT '{}',
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE public.historial_objetivos ENABLE ROW LEVEL SECURITY;

CREATE POLICY historial_objetivos_select ON public.historial_objetivos
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY historial_objetivos_insert ON public.historial_objetivos
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY historial_objetivos_update ON public.historial_objetivos
  FOR UPDATE USING (auth.uid() = usuario_id);

-- Index for fast lookup of current objective
CREATE INDEX idx_historial_objetivos_usuario
  ON public.historial_objetivos(usuario_id, fecha_inicio DESC);
