-- ============================================================================
-- Migración: Admin Panel v2
-- Descripción: Tabla de auditoría, vista de métricas globales, columnas de
--              moderación y políticas RLS adicionales para administradores.
-- ============================================================================

-- 1. Tabla de auditoría
CREATE TABLE IF NOT EXISTS public.admin_auditoria (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id        UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    accion          TEXT NOT NULL,
    entidad         TEXT NOT NULL,
    entidad_id      UUID,
    detalle         JSONB DEFAULT '{}'::jsonb,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_auditoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin read auditoria" ON public.admin_auditoria;
CREATE POLICY "Admin read auditoria" ON public.admin_auditoria
    FOR SELECT USING (public.es_admin());

DROP POLICY IF EXISTS "Admin insert auditoria" ON public.admin_auditoria;
CREATE POLICY "Admin insert auditoria" ON public.admin_auditoria
    FOR INSERT WITH CHECK (public.es_admin());

CREATE INDEX IF NOT EXISTS idx_admin_auditoria_admin ON public.admin_auditoria(admin_id, creado_en DESC);
CREATE INDEX IF NOT EXISTS idx_admin_auditoria_accion ON public.admin_auditoria(accion);

-- 2. Columnas de moderación (antes de la vista para que ésta las pueda referenciar)
DO $$ BEGIN
    ALTER TABLE public.actividades_sociales ADD COLUMN reportado BOOLEAN DEFAULT false;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE public.actividades_sociales ADD COLUMN reportado_por UUID REFERENCES public.usuarios(id);
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE public.comentarios_feed ADD COLUMN reportado BOOLEAN DEFAULT false;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE public.ejercicios ADD COLUMN activo BOOLEAN DEFAULT true;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- 3. Vista de métricas globales
DROP VIEW IF EXISTS public.v_admin_metricas;
CREATE VIEW public.v_admin_metricas AS
SELECT
    (SELECT count(*) FROM public.usuarios) AS total_usuarios,
    (SELECT count(DISTINCT usuario_id) FROM public.sesiones_registradas
     WHERE completada_en::date = CURRENT_DATE) AS usuarios_activos_hoy,
    (SELECT count(*) FROM public.sesiones_registradas
     WHERE completada_en::date = CURRENT_DATE) AS sesiones_hoy,
    (SELECT count(*) FROM public.rutinas WHERE eliminado_en IS NULL) AS rutinas_activas,
    (SELECT count(*) FROM public.retos WHERE esta_completado = false) AS retos_activos,
    (SELECT count(*) FROM public.actividades_sociales
     WHERE reportado = true)
    + (SELECT count(*) FROM public.comentarios_feed
       WHERE reportado = true AND eliminado = false) AS contenido_reportado_pendiente;

-- 4. Políticas admin RLS adicionales
DO $$ BEGIN
    DROP POLICY IF EXISTS "Admin update social" ON public.actividades_sociales;
    CREATE POLICY "Admin update social" ON public.actividades_sociales
        FOR UPDATE USING (public.es_admin());
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Admin update comentarios" ON public.comentarios_feed;
    CREATE POLICY "Admin update comentarios" ON public.comentarios_feed
        FOR UPDATE USING (public.es_admin());
EXCEPTION WHEN undefined_table THEN NULL; END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Admin update ejercicios" ON public.ejercicios;
    CREATE POLICY "Admin update ejercicios" ON public.ejercicios
        FOR UPDATE USING (public.es_admin());
EXCEPTION WHEN undefined_table THEN NULL; END $$;
