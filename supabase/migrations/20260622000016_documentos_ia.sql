-- Migration: documentos_ia — persistencia de los materiales generados por IA
--
-- Guarda los resúmenes y mapas mentales que el asistente de estudio genera a
-- partir de un apunte o de un archivo, para que el usuario pueda volver a
-- verlos sin regenerarlos (y sin gastar llamadas a la IA).
--
-- Modelo: un documento por (usuario, fuente, tipo). El UNIQUE permite UPSERT,
-- de modo que "Regenerar" sobrescribe el documento guardado.
--   * fuente_tipo: 'apunte' | 'archivo'
--   * fuente_id:   id (uuid en texto) del apunte o del archivo de origen
--   * tipo:        'resumen' (Markdown) | 'mapa_mental' (JSON serializado)

CREATE TABLE IF NOT EXISTS public.documentos_ia (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    asignatura_id   UUID,
    fuente_tipo     TEXT NOT NULL CHECK (fuente_tipo IN ('apunte', 'archivo')),
    fuente_id       TEXT NOT NULL,
    tipo            TEXT NOT NULL CHECK (tipo IN ('resumen', 'mapa_mental')),
    fuente_titulo   TEXT,
    contenido       TEXT NOT NULL,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT documentos_ia_unico
        UNIQUE (usuario_id, fuente_tipo, fuente_id, tipo)
);

ALTER TABLE public.documentos_ia ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'documentos_ia'
          AND policyname = 'Owner access documentos_ia'
    ) THEN
        CREATE POLICY "Owner access documentos_ia" ON public.documentos_ia
            FOR ALL USING (auth.uid() = usuario_id)
            WITH CHECK (auth.uid() = usuario_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_documentos_ia_fuente
    ON public.documentos_ia(usuario_id, fuente_tipo, fuente_id);
CREATE INDEX IF NOT EXISTS idx_documentos_ia_asignatura
    ON public.documentos_ia(usuario_id, asignatura_id);
