-- ============================================================
-- Migración: Social — Comentarios y moderación
-- ============================================================

-- Habilitar RLS en las tablas sociales existentes (no configurado en migraciones previas)
ALTER TABLE public.actividades_sociales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interacciones_sociales ENABLE ROW LEVEL SECURITY;

-- Políticas para actividades_sociales
DROP POLICY IF EXISTS "Lectura publica actividades" ON public.actividades_sociales;
CREATE POLICY "Lectura publica actividades" ON public.actividades_sociales
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Insercion authenticated actividades" ON public.actividades_sociales;
CREATE POLICY "Insercion authenticated actividades" ON public.actividades_sociales
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Update owner actividades" ON public.actividades_sociales;
CREATE POLICY "Update owner actividades" ON public.actividades_sociales
    FOR UPDATE USING (auth.uid() = usuario_id)
    WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Delete owner actividades" ON public.actividades_sociales;
CREATE POLICY "Delete owner actividades" ON public.actividades_sociales
    FOR DELETE USING (auth.uid() = usuario_id);

-- Políticas para interacciones_sociales
DROP POLICY IF EXISTS "Lectura publica interacciones" ON public.interacciones_sociales;
CREATE POLICY "Lectura publica interacciones" ON public.interacciones_sociales
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Insercion authenticated interacciones" ON public.interacciones_sociales;
CREATE POLICY "Insercion authenticated interacciones" ON public.interacciones_sociales
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Update owner interacciones" ON public.interacciones_sociales;
CREATE POLICY "Update owner interacciones" ON public.interacciones_sociales
    FOR UPDATE USING (auth.uid() = usuario_id)
    WITH CHECK (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Delete owner interacciones" ON public.interacciones_sociales;
CREATE POLICY "Delete owner interacciones" ON public.interacciones_sociales
    FOR DELETE USING (auth.uid() = usuario_id);

-- ============================================================
-- Tabla de comentarios independiente (más escalable)
-- ============================================================
CREATE TABLE IF NOT EXISTS comentarios_feed (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actividad_id    UUID NOT NULL REFERENCES actividades_sociales(id) ON DELETE CASCADE,
    usuario_id      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    texto           TEXT NOT NULL CHECK (char_length(texto) BETWEEN 1 AND 500),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    editado_en      TIMESTAMPTZ,
    eliminado       BOOLEAN NOT NULL DEFAULT false,
    creado_en_idx   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE comentarios_feed ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Lectura publica comentarios" ON comentarios_feed
    FOR SELECT USING (true);

CREATE POLICY "Insercion authenticated comentarios" ON comentarios_feed
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = usuario_id);

CREATE POLICY "Update owner comentarios" ON comentarios_feed
    FOR UPDATE USING (auth.uid() = usuario_id)
    WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Delete owner comentarios" ON comentarios_feed
    FOR DELETE USING (auth.uid() = usuario_id);

CREATE INDEX IF NOT EXISTS idx_comentarios_actividad ON comentarios_feed(actividad_id, creado_en);
CREATE INDEX IF NOT EXISTS idx_comentarios_usuario ON comentarios_feed(usuario_id);
