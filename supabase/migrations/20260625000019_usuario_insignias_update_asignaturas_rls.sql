-- Migration: UPDATE policy en usuario_insignias + RLS en asignaturas
--
-- 1) usuario_insignias: faltaba política de UPDATE para que la función
--    marcarNotificada() del repositorio de insignias pueda actualizar el
--    flag notificada = true (dismiss del toast de nueva insignia).
--
-- 2) asignaturas: tabla principal del dashboard de asignaturas. Tenía
--    columna usuario_id pero nunca se habilitó RLS. Cualquier usuario
--    autenticado podía leer/modificar asignaturas ajenas. Esta migración
--    habilita RLS con políticas owner + admin, consistente con el resto
--    de tablas del proyecto.

-- ── usuario_insignias: añadir UPDATE policy ──────────────────────────────

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'usuario_insignias'
          AND policyname = 'Update owner usuario_insignias'
    ) THEN
        CREATE POLICY "Update owner usuario_insignias"
            ON public.usuario_insignias
            FOR UPDATE
            USING (auth.uid() = usuario_id)
            WITH CHECK (auth.uid() = usuario_id);
    END IF;
END $$;

-- ── asignaturas: habilitar RLS + políticas ───────────────────────────────

ALTER TABLE public.asignaturas ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'asignaturas'
          AND policyname = 'Owner access asignaturas'
    ) THEN
        CREATE POLICY "Owner access asignaturas"
            ON public.asignaturas
            FOR ALL
            USING (auth.uid() = usuario_id)
            WITH CHECK (auth.uid() = usuario_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'asignaturas'
          AND policyname = 'Admin access asignaturas'
    ) THEN
        CREATE POLICY "Admin access asignaturas"
            ON public.asignaturas
            FOR ALL
            USING (public.es_admin())
            WITH CHECK (public.es_admin());
    END IF;
END $$;
