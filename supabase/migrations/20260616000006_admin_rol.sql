-- ============================================================
-- Migración 0006: Panel de Administración — Roles y Wipe
-- Propósito: Añadir columna rol, RPC wipe_user_data, RLS admin
-- ============================================================

-- 1. Añadir columna rol a usuarios
ALTER TABLE public.usuarios ADD COLUMN IF NOT EXISTS rol TEXT NOT NULL DEFAULT 'usuario'
    CHECK (rol IN ('usuario', 'admin'));

-- 2. Función helper para verificar si el usuario actual es admin
CREATE OR REPLACE FUNCTION public.es_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT coalesce((SELECT rol = 'admin' FROM public.usuarios WHERE id = auth.uid()), false);
$$;

-- ============================================================
-- 3. RPC: wipe_user_data(p_usuario_id UUID)
-- POLÍTICA:
--   CONSERVAR: perfil_bienestar_usuario, perfil_academico_usuario,
--              usuario_carreras, datos de cuenta
--   RESETEAR:  usuarios.nivel→1, xp_total→0, racha_actual→0,
--              actualizado_en→now()
--   ELIMINAR:  Todo el historial (24+ tablas)
-- ============================================================
CREATE OR REPLACE FUNCTION public.wipe_user_data(p_usuario_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_count INTEGER := 0;
    v_total INTEGER := 0;
BEGIN
    -- Verificar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE id = p_usuario_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Usuario no encontrado');
    END IF;

    -- FASE 1: DELETEs en orden bottom-up (hijos antes que padres)
    
    -- series_sesion (hijo de sesiones_registradas)
    DELETE FROM public.series_sesion WHERE sesion_id IN (
        SELECT id FROM public.sesiones_registradas WHERE usuario_id = p_usuario_id
    );
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    -- progreso_de_reto
    DELETE FROM public.progreso_de_reto WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    -- hitos_de_reto (hijo de retos)
    DELETE FROM public.hitos_de_reto WHERE reto_id IN (
        SELECT id FROM public.retos WHERE usuario_id = p_usuario_id
    );

    -- dias_rutina (hijo de semanas_rutina → rutinas)
    DELETE FROM public.dias_rutina WHERE semana_id IN (
        SELECT id FROM public.semanas_rutina WHERE rutina_id IN (
            SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id
        )
    );

    -- semanas_rutina (hijo de rutinas)
    DELETE FROM public.semanas_rutina WHERE rutina_id IN (
        SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id
    );

    -- seleccion_de_ejercicios (hijo de rutinas)
    DELETE FROM public.seleccion_de_ejercicios WHERE rutina_id IN (
        SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id
    );

    -- Tablas con usuario_id directo
    DELETE FROM public.sesiones_registradas WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.rutinas WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.retos WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.entregas_examenes WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.horarios_academicos WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.asignaturas WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.interacciones_sociales WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.actividades_sociales WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.comentarios_feed WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.planes_estudio WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.apuntes WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.sesiones_focus WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.usuario_insignias WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.amistades WHERE solicitante_id = p_usuario_id OR receptor_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.carga_academica_semanal WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.estado_diario_usuario WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.historial_objetivos WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.historial_peso WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.notificaciones WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.plan_entrenamiento_semanal WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.preferencias_notificacion WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    DELETE FROM public.recomendaciones_pendientes WHERE usuario_id = p_usuario_id;
    GET DIAGNOSTICS v_count = ROW_COUNT; v_total := v_total + v_count;

    -- FASE 2: RESETEAR valores dinámicos en usuarios
    UPDATE public.usuarios
    SET nivel = 1,
        xp_total = 0,
        racha_actual = 0,
        actualizado_en = now()
    WHERE id = p_usuario_id;

    -- FASE 3: Retornar resumen
    RETURN jsonb_build_object(
        'success', true,
        'usuario_id', p_usuario_id,
        'registros_eliminados', v_total
    );
END;
$$;

-- Permisos para el RPC
GRANT EXECUTE ON FUNCTION public.wipe_user_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.es_admin() TO authenticated;

-- ============================================================
-- 4. Políticas RLS para admin bypass
-- ============================================================

-- Admin puede leer todos los usuarios
DROP POLICY IF EXISTS "Admin read all usuarios" ON public.usuarios;
CREATE POLICY "Admin read all usuarios" ON public.usuarios
    FOR SELECT USING (public.es_admin());

-- Admin puede actualizar usuarios
DROP POLICY IF EXISTS "Admin update usuarios" ON public.usuarios;
CREATE POLICY "Admin update usuarios" ON public.usuarios
    FOR UPDATE USING (public.es_admin()) WITH CHECK (public.es_admin());

-- Admin puede leer sesiones de todos los usuarios (para stats)
DROP POLICY IF EXISTS "Admin read all sesiones" ON public.sesiones_registradas;
CREATE POLICY "Admin read all sesiones" ON public.sesiones_registradas
    FOR SELECT USING (public.es_admin());
