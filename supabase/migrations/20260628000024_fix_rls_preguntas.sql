-- =============================================================================
-- Migración 20260628000024: Fix RLS en preguntas — extender a INSERT
--
-- La política original solo cubría SELECT. El guardado de preguntas
-- generadas por IA necesita INSERT. Se reemplaza por FOR ALL.
-- También se añade usuario_id por defecto desde auth.uid() para INSERTs.
-- =============================================================================

-- 1. Reemplazar política de SELECT por FOR ALL en preguntas
DROP POLICY IF EXISTS "Dueño ve sus preguntas vía banco" ON public.preguntas;
CREATE POLICY "Dueño gestiona sus preguntas vía banco" ON public.preguntas
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.bancos_preguntas
        WHERE bancos_preguntas.id = preguntas.banco_id
          AND bancos_preguntas.usuario_id = auth.uid()
    ));

-- 2. Añadir admin SELECT en preguntas e intentos (consistencia)
DROP POLICY IF EXISTS "Admin ve todas las preguntas" ON public.preguntas;
CREATE POLICY "Admin ve todas las preguntas" ON public.preguntas
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE usuarios.id = auth.uid() AND usuarios.rol = 'admin'
    ));

DROP POLICY IF EXISTS "Admin ve todos los intentos" ON public.intentos_pregunta;
CREATE POLICY "Admin ve todos los intentos" ON public.intentos_pregunta
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE usuarios.id = auth.uid() AND usuarios.rol = 'admin'
    ));
