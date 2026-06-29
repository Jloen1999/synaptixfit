-- =============================================================================
-- Migración 20260628000025: Test Sessions — Sesiones de práctica persistentes
--
-- Introduce test_sessions para separar el banco de preguntas (QuestionBank)
-- de cada sesión de práctica individual. Cada sesión toma un subconjunto del
-- banco, guarda respuestas y resultados, y permite retomar sesiones activas.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.test_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    material_id     UUID NOT NULL REFERENCES public.materiales_estudio(id) ON DELETE CASCADE,
    preguntas_ids   JSONB NOT NULL DEFAULT '[]',
    respuestas      JSONB NOT NULL DEFAULT '{}',
    resultados      JSONB NOT NULL DEFAULT '{}',
    indice_actual   INTEGER NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'in_progress'
        CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    score           INTEGER NOT NULL DEFAULT 0,
    total_preguntas INTEGER NOT NULL DEFAULT 0,
    iniciado_en     TIMESTAMPTZ NOT NULL DEFAULT now(),
    completado_en   TIMESTAMPTZ,
    xp_otorgado     BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_test_sessions_usuario
    ON public.test_sessions(usuario_id, material_id, status);

-- RLS
ALTER TABLE public.test_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Dueño gestiona sus sesiones" ON public.test_sessions;
CREATE POLICY "Dueño gestiona sus sesiones" ON public.test_sessions
    FOR ALL
    USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Admin ve todas las sesiones" ON public.test_sessions;
CREATE POLICY "Admin ve todas las sesiones" ON public.test_sessions
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE usuarios.id = auth.uid() AND usuarios.rol = 'admin'
    ));
