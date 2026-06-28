-- =============================================================================
-- Migración 20260628000023: Bancos de Preguntas — Generación IA + SM-2
--
-- Crea las tablas para alojar tests generados por IA (opción múltiple
-- y rellenar huecos) asociados a materiales de estudio, junto con el
-- historial de intentos del usuario.
-- =============================================================================

-- 1. Banco de preguntas asociado a un material de estudio
CREATE TABLE IF NOT EXISTS public.bancos_preguntas (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id       UUID NOT NULL REFERENCES public.materiales_estudio(id) ON DELETE CASCADE,
    usuario_id        UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    xp_otorgado       BOOLEAN NOT NULL DEFAULT false,
    generado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bancos_material
    ON public.bancos_preguntas(material_id);

-- 2. Pregunta individual
CREATE TABLE IF NOT EXISTS public.preguntas (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    banco_id            UUID NOT NULL REFERENCES public.bancos_preguntas(id) ON DELETE CASCADE,
    tipo                TEXT NOT NULL CHECK (tipo IN ('opcion_multiple', 'rellenar_hueco')),
    enunciado           TEXT NOT NULL,
    opciones            JSONB,
    respuesta_correcta  TEXT NOT NULL,
    explicacion         TEXT,
    orden               INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_preguntas_banco
    ON public.preguntas(banco_id);

-- 3. Historial de intentos del usuario por pregunta
CREATE TABLE IF NOT EXISTS public.intentos_pregunta (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id        UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    pregunta_id       UUID NOT NULL REFERENCES public.preguntas(id) ON DELETE CASCADE,
    es_correcta       BOOLEAN NOT NULL,
    respondido_en     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_intentos_usuario_pregunta
    ON public.intentos_pregunta(usuario_id, pregunta_id);

-- 4. RLS: solo el dueño gestiona sus bancos
ALTER TABLE public.bancos_preguntas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Dueño gestiona sus bancos" ON public.bancos_preguntas;
CREATE POLICY "Dueño gestiona sus bancos" ON public.bancos_preguntas
    FOR ALL
    USING (auth.uid() = usuario_id);

-- 5. RLS: preguntas visibles a través del banco del dueño
ALTER TABLE public.preguntas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Dueño ve sus preguntas vía banco" ON public.preguntas;
CREATE POLICY "Dueño ve sus preguntas vía banco" ON public.preguntas
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.bancos_preguntas
        WHERE bancos_preguntas.id = preguntas.banco_id
          AND bancos_preguntas.usuario_id = auth.uid()
    ));

-- 6. RLS: intentos del propio usuario
ALTER TABLE public.intentos_pregunta ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Dueño gestiona sus intentos" ON public.intentos_pregunta;
CREATE POLICY "Dueño gestiona sus intentos" ON public.intentos_pregunta
    FOR ALL
    USING (auth.uid() = usuario_id);

-- 7. Admin puede ver todo
DROP POLICY IF EXISTS "Admin ve todos los bancos" ON public.bancos_preguntas;
CREATE POLICY "Admin ve todos los bancos" ON public.bancos_preguntas
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE usuarios.id = auth.uid() AND usuarios.rol = 'admin'
    ));
