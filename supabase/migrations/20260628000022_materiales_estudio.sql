-- =============================================================================
-- Migración 20260628000022: Materiales de Estudio — Fundación SM-2
--
-- Crea la tabla wrapper materiales_estudio que unifica apuntes y archivos 
-- bajo una jerarquía de repaso espaciado, y amplía los CHECKs de
-- documentos_ia y horarios_academicos para los nuevos tipos 'practica'
-- y 'repaso'.
-- =============================================================================

-- 1. Tabla materiales_estudio (wrapper de apuntes + archivos_asignatura)
CREATE TABLE IF NOT EXISTS public.materiales_estudio (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id            UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    asignatura_id         UUID NOT NULL REFERENCES public.asignaturas(id) ON DELETE CASCADE,

    tipo_origen           TEXT NOT NULL CHECK (tipo_origen IN ('archivo', 'apunte')),
    origen_id             UUID NOT NULL,
    titulo                TEXT NOT NULL,
    creado_en             TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- SM-2 Spaced Repetition
    estado_dominio        TEXT NOT NULL DEFAULT 'sin_evaluar'
        CHECK (estado_dominio IN (
            'sin_evaluar', 'dominado', 'en_progreso', 'necesita_repaso', 'abandonado'
        )),
    ultimo_repaso_en      TIMESTAMPTZ,
    siguiente_repaso_en   TIMESTAMPTZ,
    intervalo_actual_dias INTEGER DEFAULT 0,
    facilidad             REAL DEFAULT 2.5,
    repasos_completados   INTEGER DEFAULT 0,
    repasos_fallidos      INTEGER DEFAULT 0,
    xp_practica_otorgado  BOOLEAN NOT NULL DEFAULT false,

    UNIQUE (usuario_id, tipo_origen, origen_id)
);

-- 2. Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_materiales_usuario_asignatura
    ON public.materiales_estudio(usuario_id, asignatura_id);

CREATE INDEX IF NOT EXISTS idx_materiales_siguiente_repaso
    ON public.materiales_estudio(usuario_id, siguiente_repaso_en)
    WHERE siguiente_repaso_en IS NOT NULL;

-- 3. Ampliar CHECK de tipo_actividad en horarios_academicos para 'repaso'
ALTER TABLE public.horarios_academicos
    DROP CONSTRAINT IF EXISTS ck_horarios_tipo_actividad;

ALTER TABLE public.horarios_academicos
    ADD CONSTRAINT ck_horarios_tipo_actividad
    CHECK (tipo_actividad = ANY (ARRAY[
        'estudio', 'deporte', 'clase', 'descanso', 'comida',
        'sueno', 'examen', 'entrega', 'repaso'
    ]));

-- 4. Ampliar CHECK de tipo en documentos_ia para 'practica'
ALTER TABLE public.documentos_ia
    DROP CONSTRAINT IF EXISTS documentos_ia_tipo_check;

ALTER TABLE public.documentos_ia
    ADD CONSTRAINT documentos_ia_tipo_check
    CHECK (tipo IN ('resumen', 'mapa_mental', 'guia_docente', 'practica'));

-- 5. Ampliar CHECK de fuente_tipo en documentos_ia para incluir
--    valores adicionales que serán necesarios en fases futuras
ALTER TABLE public.documentos_ia
    DROP CONSTRAINT IF EXISTS documentos_ia_fuente_tipo_check;

ALTER TABLE public.documentos_ia
    ADD CONSTRAINT documentos_ia_fuente_tipo_check
    CHECK (fuente_tipo IN ('apunte', 'archivo', 'guia_docente', 'practica'));

-- 6. RLS: solo el dueño ve/modifica sus materiales
ALTER TABLE public.materiales_estudio ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Dueño gestiona sus materiales" ON public.materiales_estudio;
CREATE POLICY "Dueño gestiona sus materiales" ON public.materiales_estudio
    FOR ALL
    USING (auth.uid() = usuario_id);

DROP POLICY IF EXISTS "Admin ve todos los materiales" ON public.materiales_estudio;
CREATE POLICY "Admin ve todos los materiales" ON public.materiales_estudio
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE usuarios.id = auth.uid() AND usuarios.rol = 'admin'
    ));
