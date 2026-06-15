-- ============================================================
-- Migración 0004: Consolidación de correcciones de esquema
-- Propósito: Añadir columnas, tablas y vistas faltantes que
-- el código Dart asume pero no existen en la BD.
-- Idempotente: usa IF NOT EXISTS / IF EXISTS en todo.
-- ============================================================

-- ============================================================
-- SECCIÓN 1: CREAR TABLAS FALTANTES
-- ============================================================

-- 1a. planes_estudio
-- Usada por planes_estudio_provider.dart (INSERT/SELECT/DELETE)
CREATE TABLE IF NOT EXISTS public.planes_estudio (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    nombre          TEXT NOT NULL DEFAULT 'Plan de estudio',
    semana_inicio   DATE NOT NULL DEFAULT CURRENT_DATE,
    semana_fin      DATE,
    visibilidad     TEXT NOT NULL DEFAULT 'private' CHECK (visibilidad IN ('private', 'friends', 'public')),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.planes_estudio ENABLE ROW LEVEL SECURITY;

-- Política: solo el dueño puede acceder
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'planes_estudio'
          AND policyname = 'Owner access planes_estudio'
    ) THEN
        CREATE POLICY "Owner access planes_estudio" ON public.planes_estudio
            FOR ALL USING (auth.uid() = usuario_id)
            WITH CHECK (auth.uid() = usuario_id);
    END IF;
END $$;


-- 1b. apuntes
-- Usada por escanear_provider.dart:122-129 (INSERT con estos campos)
CREATE TABLE IF NOT EXISTS public.apuntes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    titulo          TEXT NOT NULL DEFAULT 'Apunte escaneado',
    contenido       TEXT NOT NULL DEFAULT '',
    asignatura_id   UUID REFERENCES public.asignaturas(id) ON DELETE SET NULL,
    visibilidad     TEXT NOT NULL DEFAULT 'private' CHECK (visibilidad IN ('private', 'friends', 'public')),
    es_nota_rapida  BOOLEAN NOT NULL DEFAULT false,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.apuntes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'apuntes'
          AND policyname = 'Owner access apuntes'
    ) THEN
        CREATE POLICY "Owner access apuntes" ON public.apuntes
            FOR ALL USING (auth.uid() = usuario_id)
            WITH CHECK (auth.uid() = usuario_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_apuntes_usuario ON public.apuntes(usuario_id, creado_en DESC);


-- 1c. sesiones_focus (Pomodoro)
-- Usada por pomodoro_provider.dart para registrar sesiones de enfoque
CREATE TABLE IF NOT EXISTS public.sesiones_focus (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id          UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    duracion_minutos    INTEGER NOT NULL DEFAULT 25,
    ciclos_completados  INTEGER NOT NULL DEFAULT 1,
    tipo_fase           TEXT NOT NULL DEFAULT 'focus' CHECK (tipo_fase IN ('focus', 'short_break', 'long_break')),
    completada          BOOLEAN NOT NULL DEFAULT true,
    fecha               DATE NOT NULL DEFAULT CURRENT_DATE,
    creado_en           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.sesiones_focus ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'sesiones_focus'
          AND policyname = 'Owner access sesiones_focus'
    ) THEN
        CREATE POLICY "Owner access sesiones_focus" ON public.sesiones_focus
            FOR ALL USING (auth.uid() = usuario_id)
            WITH CHECK (auth.uid() = usuario_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sesiones_focus_usuario_fecha ON public.sesiones_focus(usuario_id, fecha DESC);


-- ============================================================
-- SECCIÓN 2: CREAR VISTAS FALTANTES
-- ============================================================

-- 2a. v_ejercicios_completos
-- Usada por ejercicios_repository.dart (6 queries) y rutina_detalle_screen.dart.
-- Une ejercicios con sus tablas relacionadas (músculos, partes del cuerpo, equipamientos).
-- NOTA: instrucciones, finalidad y tipo_medicion se mantienen como arrays (text[])
--       tal como vienen de la tabla ejercicios.
DROP VIEW IF EXISTS public.v_ejercicios_completos CASCADE;
CREATE OR REPLACE VIEW public.v_ejercicios_completos AS
SELECT
    e.id,
    e.nombre,
    e.url_gif,
    e.url_preview,
    e.instrucciones,
    e.dificultad,
    e.descripcion,
    e.finalidad,
    e.modalidad_entrenamiento,
    e.tipo_medicion,
    e.es_circuito,
    COALESCE(
        (SELECT string_agg(DISTINCT pc.nombre, ', ')
         FROM public.ejercicio_parte_cuerpo epc
         JOIN public.partes_cuerpo pc ON pc.id = epc.parte_cuerpo_id
         WHERE epc.ejercicio_id = e.id), ''
    ) AS partes_cuerpo,
    COALESCE(
        (SELECT string_agg(DISTINCT m.nombre, ', ')
         FROM public.ejercicio_musculo_objetivo emo
         JOIN public.musculos m ON m.id = emo.musculo_id
         WHERE emo.ejercicio_id = e.id), ''
    ) AS musculos_objetivo,
    COALESCE(
        (SELECT string_agg(DISTINCT m.nombre, ', ')
         FROM public.ejercicio_musculo_secundario ems
         JOIN public.musculos m ON m.id = ems.musculo_id
         WHERE ems.ejercicio_id = e.id), ''
    ) AS musculos_secundarios,
    COALESCE(
        (SELECT string_agg(DISTINCT eq.nombre, ', ')
         FROM public.ejercicio_equipamiento eeq
         JOIN public.equipamientos eq ON eq.id = eeq.equipamiento_id
         WHERE eeq.ejercicio_id = e.id), ''
    ) AS equipamientos,
    e.creado_en
FROM public.ejercicios e;


-- ============================================================
-- SECCIÓN 3: AÑADIR COLUMNAS FALTANTES
-- ============================================================

-- 3a. rutinas (+3 columnas)
ALTER TABLE public.rutinas ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'activo';
ALTER TABLE public.rutinas ADD COLUMN IF NOT EXISTS objetivo TEXT NOT NULL DEFAULT 'fuerza';
ALTER TABLE public.rutinas ADD COLUMN IF NOT EXISTS duracion_semanas INTEGER NOT NULL DEFAULT 1;

-- 3b. asignaturas (+2 columnas)
ALTER TABLE public.asignaturas ADD COLUMN IF NOT EXISTS archivado BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.asignaturas ADD COLUMN IF NOT EXISTS docente TEXT;

-- 3c. horarios_academicos (+5 columnas)
ALTER TABLE public.horarios_academicos ADD COLUMN IF NOT EXISTS plan_estudio_id UUID REFERENCES public.planes_estudio(id) ON DELETE SET NULL;
ALTER TABLE public.horarios_academicos ADD COLUMN IF NOT EXISTS prioridad TEXT NOT NULL DEFAULT 'media';
ALTER TABLE public.horarios_academicos ADD COLUMN IF NOT EXISTS tipo_actividad TEXT NOT NULL DEFAULT 'estudio';
ALTER TABLE public.horarios_academicos ADD COLUMN IF NOT EXISTS rutina_id UUID;
ALTER TABLE public.horarios_academicos ADD COLUMN IF NOT EXISTS temas TEXT;

-- 3d. seleccion_de_ejercicios (+1 columna)
ALTER TABLE public.seleccion_de_ejercicios ADD COLUMN IF NOT EXISTS dia_id UUID REFERENCES public.dias_rutina(id) ON DELETE CASCADE;

-- 3e. sesiones_registradas (+2 columnas)
ALTER TABLE public.sesiones_registradas ADD COLUMN IF NOT EXISTS dia_id UUID REFERENCES public.dias_rutina(id) ON DELETE SET NULL;
ALTER TABLE public.sesiones_registradas ADD COLUMN IF NOT EXISTS tipo TEXT NOT NULL DEFAULT 'libre';

-- 3f. perfil_bienestar_usuario (+1 columna)
ALTER TABLE public.perfil_bienestar_usuario ADD COLUMN IF NOT EXISTS ciudad TEXT;

-- 3g. actividades_sociales (+1 columna)
ALTER TABLE public.actividades_sociales ADD COLUMN IF NOT EXISTS metadata TEXT;

-- 3h. hitos_de_reto (+4 columnas para dependencias)
ALTER TABLE public.hitos_de_reto ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'bloqueado';
ALTER TABLE public.hitos_de_reto ADD COLUMN IF NOT EXISTS dependencias UUID[] DEFAULT '{}'::uuid[];
ALTER TABLE public.hitos_de_reto ADD COLUMN IF NOT EXISTS tipo_condicion TEXT NOT NULL DEFAULT 'AND';
ALTER TABLE public.hitos_de_reto ADD COLUMN IF NOT EXISTS condicion_n INTEGER NOT NULL DEFAULT 1;

-- 3i. retos — columna tiene_dependencias
ALTER TABLE public.retos ADD COLUMN IF NOT EXISTS tiene_dependencias BOOLEAN NOT NULL DEFAULT false;


-- ============================================================
-- SECCIÓN 4: CORREGIR CONSTRAINTS
-- ============================================================

-- 4a. Ampliar CHECK de notificaciones.prioridad para aceptar 'baja'
--     El constraint actual solo permite ['critical', 'recommended', 'informative']
--     Se elimina (si existe) y se recrea con el array ampliado.
DO $$
BEGIN
    ALTER TABLE public.notificaciones DROP CONSTRAINT IF EXISTS notificaciones_prioridad_check;
EXCEPTION WHEN undefined_object THEN
    -- Si la tabla no existe aún, ignorar silenciosamente
    NULL;
END $$;

DO $$
BEGIN
    -- Solo crear el constraint si la tabla existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'notificaciones'
    ) THEN
        -- Agregar NOT VALID para evitar validación retroactiva de datos existentes
        ALTER TABLE public.notificaciones
            ADD CONSTRAINT notificaciones_prioridad_check
            CHECK (prioridad = ANY (ARRAY['critical', 'recommended', 'informative', 'baja']))
            NOT VALID;
    END IF;
END $$;


-- ============================================================
-- SECCIÓN 5: ÍNDICES PARA RENDIMIENTO
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_rutinas_usuario_estado ON public.rutinas(usuario_id, estado);
CREATE INDEX IF NOT EXISTS idx_horarios_academicos_plan ON public.horarios_academicos(plan_estudio_id);
CREATE INDEX IF NOT EXISTS idx_horarios_academicos_tipo ON public.horarios_academicos(tipo_actividad);
CREATE INDEX IF NOT EXISTS idx_sesiones_dia ON public.sesiones_registradas(dia_id);
CREATE INDEX IF NOT EXISTS idx_seleccion_ejercicios_dia ON public.seleccion_de_ejercicios(dia_id);


-- ============================================================
-- SECCIÓN 6: VERIFICACIÓN FINAL
-- ============================================================

DO $$
DECLARE
    tbl_count INTEGER;
    col_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO tbl_count FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
    SELECT COUNT(*) INTO col_count FROM information_schema.columns
        WHERE table_schema = 'public';
    RAISE NOTICE 'Migración 0004 aplicada: % tablas, % columnas totales en schema public', tbl_count, col_count;
END $$;
