-- =============================================================================
-- 0048: recomendaciones_pendientes — post-session adjustment suggestions
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.recomendaciones_pendientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('progresion','degradacion','descarga','variante','academico')),
  titulo TEXT NOT NULL,
  descripcion TEXT,
  ejercicio_id UUID REFERENCES public.ejercicios(id) ON DELETE SET NULL,
  rutina_id UUID REFERENCES public.rutinas(id) ON DELETE SET NULL,
  datos JSONB DEFAULT '{}',
  aplicada BOOLEAN NOT NULL DEFAULT false,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.recomendaciones_pendientes ENABLE ROW LEVEL SECURITY;

CREATE POLICY recom_pend_select ON public.recomendaciones_pendientes
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY recom_pend_insert ON public.recomendaciones_pendientes
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY recom_pend_update ON public.recomendaciones_pendientes
  FOR UPDATE USING (auth.uid() = usuario_id);

CREATE INDEX idx_recom_pend_usuario
  ON public.recomendaciones_pendientes(usuario_id, creado_en DESC);
