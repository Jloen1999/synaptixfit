-- Migración: Eliminación permanente de usuarios (hard delete) para panel admin
-- Añade RPC delete_user() que elimina un usuario y todos sus datos en cascada.
-- Solo administradores pueden ejecutarla, y no pueden auto-eliminarse.

-- RPC para eliminar permanentemente un usuario y todos sus datos dependientes
CREATE OR REPLACE FUNCTION public.delete_user(p_usuario_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_user_email TEXT;
BEGIN
  -- Verificar que quien ejecuta es admin
  SELECT u.id INTO v_admin_id FROM public.usuarios u
  WHERE u.id = auth.uid() AND u.rol = 'admin';
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Solo administradores pueden eliminar usuarios';
  END IF;

  -- No auto-eliminarse
  IF v_admin_id = p_usuario_id THEN
    RAISE EXCEPTION 'No puedes eliminar tu propio usuario';
  END IF;

  -- Guardar email para la respuesta
  SELECT email INTO v_user_email FROM public.usuarios WHERE id = p_usuario_id;

  IF v_user_email IS NULL THEN
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  -- Eliminar registros dependientes en orden por FK constraints
  DELETE FROM public.admin_auditoria WHERE admin_id = p_usuario_id OR entidad_id = p_usuario_id;
  DELETE FROM public.comentarios_feed WHERE usuario_id = p_usuario_id;
  DELETE FROM public.actividades_sociales WHERE usuario_id = p_usuario_id;
  DELETE FROM public.usuario_insignias WHERE usuario_id = p_usuario_id;
  DELETE FROM public.seleccion_de_ejercicios WHERE rutina_id IN (SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id);
  DELETE FROM public.series_realizadas WHERE sesion_id IN (SELECT id FROM public.sesiones_registradas WHERE usuario_id = p_usuario_id);
  DELETE FROM public.sesiones_registradas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.rutinas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.retos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.notificaciones WHERE usuario_id = p_usuario_id;
  DELETE FROM public.horarios_academicos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.apuntes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.carga_academica_semanal WHERE usuario_id = p_usuario_id;
  DELETE FROM public.estado_diario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.historial_peso WHERE usuario_id = p_usuario_id;
  DELETE FROM public.plan_entrenamiento_semanal WHERE usuario_id = p_usuario_id;
  DELETE FROM public.perfil_bienestar_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.perfil_academico_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.asignaturas_usuario_semestre WHERE usuario_id = p_usuario_id;
  DELETE FROM public.preferencias_notificacion WHERE usuario_id = p_usuario_id;
  DELETE FROM public.usuarios WHERE id = p_usuario_id;

  RETURN jsonb_build_object('success', true, 'email', v_user_email);
END;
$$;
