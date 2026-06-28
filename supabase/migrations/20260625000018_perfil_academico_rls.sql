-- Migration: RLS en perfil_academico_usuario
--
-- El Academic Control Center (nueva feature del Dashboard de Asignatura)
-- hace UPDATE en la tabla perfil_academico_usuario para guardar las fechas
-- de inicio/fin del semestre. Esta tabla no tenía RLS habilitada, lo que
-- exponía datos académicos de todos los usuarios.
--
-- Esta migración habilita RLS y añade políticas owner + admin.

ALTER TABLE public.perfil_academico_usuario ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'perfil_academico_usuario'
          AND policyname = 'Owner access perfil_academico'
    ) THEN
        CREATE POLICY "Owner access perfil_academico"
            ON public.perfil_academico_usuario
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
          AND tablename = 'perfil_academico_usuario'
          AND policyname = 'Admin access perfil_academico'
    ) THEN
        CREATE POLICY "Admin access perfil_academico"
            ON public.perfil_academico_usuario
            FOR ALL
            USING (public.es_admin())
            WITH CHECK (public.es_admin());
    END IF;
END $$;
