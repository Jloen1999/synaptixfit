-- ============================================================================
-- Migración 20260701000030: GDPR — Anonimización quirúrgica + Exportación
-- ============================================================================

BEGIN;

-- ── A. RPC: anonymize_user — Derecho al Olvido con preservación analítica ──

CREATE OR REPLACE FUNCTION public.anonymize_user(p_usuario_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id  UUID;
  v_email     TEXT;
  v_anon_id   UUID;
  v_count     INTEGER;
  v_total_anonimizados INTEGER := 0;
  v_total_eliminados   INTEGER := 0;
BEGIN
  SELECT u.id INTO v_admin_id FROM public.usuarios u
  WHERE u.id = auth.uid() AND u.rol = 'admin';
  IF v_admin_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Solo administradores pueden anonimizar');
  END IF;

  IF v_admin_id = p_usuario_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'No puedes anonimizar tu propio usuario');
  END IF;

  SELECT email INTO v_email FROM public.usuarios WHERE id = p_usuario_id;
  IF v_email IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Usuario no encontrado');
  END IF;

  v_anon_id := gen_random_uuid();

  -- FASE 1: ANONIMIZAR — reemplazar usuario_id por UUID anónimo
  UPDATE public.sesiones_registradas
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  v_total_anonimizados := v_total_anonimizados + v_count;

  UPDATE public.carga_academica_semanal
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  v_total_anonimizados := v_total_anonimizados + v_count;

  UPDATE public.horarios_academicos
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  v_total_anonimizados := v_total_anonimizados + v_count;

  UPDATE public.estado_cognitivo_usuario
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;

  UPDATE public.estado_regulacion_cruzada
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;

  UPDATE public.registros_carga_fisica
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;

  UPDATE public.estado_diario_usuario
    SET usuario_id = v_anon_id WHERE usuario_id = p_usuario_id;

  -- FASE 2: ELIMINAR datos personales y contenido identificable
  DELETE FROM public.admin_auditoria WHERE entidad_id = p_usuario_id;

  DELETE FROM public.comentarios_feed WHERE usuario_id = p_usuario_id;
  DELETE FROM public.actividades_sociales WHERE usuario_id = p_usuario_id;
  DELETE FROM public.interacciones_sociales WHERE usuario_id = p_usuario_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  v_total_eliminados := v_total_eliminados + v_count;

  DELETE FROM public.amistades WHERE solicitante_id = p_usuario_id OR receptor_id = p_usuario_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  v_total_eliminados := v_total_eliminados + v_count;

  DELETE FROM public.usuario_insignias WHERE usuario_id = p_usuario_id;

  DELETE FROM public.seleccion_de_ejercicios WHERE rutina_id IN (
    SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id
  );
  DELETE FROM public.dias_rutina WHERE semana_id IN (
    SELECT id FROM public.semanas_rutina WHERE rutina_id IN (
      SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id
    )
  );
  DELETE FROM public.semanas_rutina WHERE rutina_id IN (
    SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id
  );
  DELETE FROM public.rutinas WHERE usuario_id = p_usuario_id;

  DELETE FROM public.progreso_de_reto WHERE usuario_id = p_usuario_id;
  DELETE FROM public.hitos_de_reto WHERE reto_id IN (
    SELECT id FROM public.retos WHERE usuario_id = p_usuario_id
  );
  DELETE FROM public.retos WHERE usuario_id = p_usuario_id;

  DELETE FROM public.entregas_examenes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.materiales_estudio WHERE usuario_id = p_usuario_id;
  DELETE FROM public.planes_estudio WHERE usuario_id = p_usuario_id;
  DELETE FROM public.apuntes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.documentos_ia WHERE usuario_id = p_usuario_id;
  DELETE FROM public.sesiones_focus WHERE usuario_id = p_usuario_id;

  DELETE FROM public.perfil_bienestar_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.perfil_academico_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.historial_peso WHERE usuario_id = p_usuario_id;
  DELETE FROM public.historial_objetivos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.preferencias_notificacion WHERE usuario_id = p_usuario_id;

  DELETE FROM public.asignaturas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.asignaturas_usuario_semestre WHERE usuario_id = p_usuario_id;

  DELETE FROM public.notificaciones WHERE usuario_id = p_usuario_id;
  DELETE FROM public.recomendaciones_pendientes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.plan_entrenamiento_semanal WHERE usuario_id = p_usuario_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  v_total_eliminados := v_total_eliminados + v_count;

  -- FASE 3: Destruir identidad
  DELETE FROM public.usuarios WHERE id = p_usuario_id;
  DELETE FROM auth.users WHERE id = p_usuario_id;

  INSERT INTO public.admin_auditoria (admin_id, accion, entidad, entidad_id, detalle)
  VALUES (
    v_admin_id, 'anonimizar_usuario', 'usuarios', p_usuario_id,
    jsonb_build_object(
      'email_anonimizado', v_email,
      'anon_id_asignado', v_anon_id,
      'registros_anonimizados', v_total_anonimizados,
      'registros_eliminados', v_total_eliminados
    )
  );

  RETURN jsonb_build_object(
    'success', true, 'email', v_email, 'anon_id', v_anon_id,
    'anonimizados', v_total_anonimizados, 'eliminados', v_total_eliminados
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.anonymize_user(UUID) TO authenticated;

-- ── B. RPC: exportar_datos_usuario — Derecho a la Portabilidad (GDPR) ──────

CREATE OR REPLACE FUNCTION public.exportar_datos_usuario(p_usuario_id UUID)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_result   jsonb;
BEGIN
  SELECT u.id INTO v_admin_id FROM public.usuarios u
  WHERE u.id = auth.uid() AND u.rol = 'admin';
  IF v_admin_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Solo administradores pueden exportar datos');
  END IF;

  SELECT jsonb_build_object(
    'exportado_en', now(),
    'usuario_id', p_usuario_id,

    'perfil', (
      SELECT jsonb_build_object(
        'id', u.id,
        'email', u.email,
        'nombre_completo', u.nombre_completo,
        'url_avatar', u.url_avatar,
        'nivel', u.nivel,
        'xp_total', u.xp_total,
        'racha_actual', u.racha_actual,
        'rol', u.rol,
        'nivel_privacidad', u.nivel_privacidad,
        'is_shadowbanned', u.is_shadowbanned,
        'creado_en', u.creado_en,
        'actualizado_en', u.actualizado_en
      ) FROM public.usuarios u WHERE u.id = p_usuario_id
    ),

    'perfil_bienestar', (
      SELECT row_to_json(p) FROM public.perfil_bienestar_usuario p
      WHERE p.usuario_id = p_usuario_id
    ),

    'perfil_academico', (
      SELECT row_to_json(p) FROM public.perfil_academico_usuario p
      WHERE p.usuario_id = p_usuario_id
    ),

    'historial_peso', (
      SELECT jsonb_agg(row_to_json(h) ORDER BY h.registrado_en DESC)
      FROM public.historial_peso h WHERE h.usuario_id = p_usuario_id
    ),

    'sesiones_registradas', (
      SELECT jsonb_agg(row_to_json(s) ORDER BY s.completada_en DESC)
      FROM public.sesiones_registradas s WHERE s.usuario_id = p_usuario_id
    ),

    'carga_academica_semanal', (
      SELECT jsonb_agg(row_to_json(c) ORDER BY c.semana_inicio DESC)
      FROM public.carga_academica_semanal c WHERE c.usuario_id = p_usuario_id
    ),

    'horarios_academicos', (
      SELECT jsonb_agg(row_to_json(h) ORDER BY h.fecha DESC, h.hora_inicio)
      FROM public.horarios_academicos h WHERE h.usuario_id = p_usuario_id
    ),

    'rutinas', (
      SELECT jsonb_agg(row_to_json(r) ORDER BY r.creado_en DESC)
      FROM public.rutinas r WHERE r.usuario_id = p_usuario_id AND r.eliminado_en IS NULL
    ),

    'retos', (
      SELECT jsonb_agg(row_to_json(r) ORDER BY r.creado_en DESC)
      FROM public.retos r WHERE r.usuario_id = p_usuario_id
    ),

    'materiales_estudio', (
      SELECT jsonb_agg(row_to_json(m) ORDER BY m.creado_en DESC)
      FROM public.materiales_estudio m WHERE m.usuario_id = p_usuario_id
    ),

    'apuntes', (
      SELECT jsonb_agg(row_to_json(a) ORDER BY a.creado_en DESC)
      FROM public.apuntes a WHERE a.usuario_id = p_usuario_id
    ),

    'documentos_ia', (
      SELECT jsonb_agg(row_to_json(d) ORDER BY d.creado_en DESC)
      FROM public.documentos_ia d WHERE d.usuario_id = p_usuario_id
    ),

    'actividades_sociales', (
      SELECT jsonb_agg(row_to_json(a) ORDER BY a.creado_en DESC)
      FROM public.actividades_sociales a WHERE a.usuario_id = p_usuario_id
    ),

    'comentarios_feed', (
      SELECT jsonb_agg(row_to_json(c) ORDER BY c.creado_en DESC)
      FROM public.comentarios_feed c WHERE c.usuario_id = p_usuario_id
    ),

    'insignias', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'insignia_id', ui.insignia_id,
          'obtenida_en', ui.creado_en,
          'notificada', ui.notificada
        ) ORDER BY ui.creado_en DESC
      )
      FROM public.usuario_insignias ui WHERE ui.usuario_id = p_usuario_id
    ),

    'amistades', (
      SELECT jsonb_agg(row_to_json(a) ORDER BY a.creado_en DESC)
      FROM public.amistades a
      WHERE a.solicitante_id = p_usuario_id OR a.receptor_id = p_usuario_id
    ),

    'notificaciones', (
      SELECT jsonb_agg(row_to_json(n) ORDER BY n.creado_en DESC)
      FROM public.notificaciones n WHERE n.usuario_id = p_usuario_id
    ),

    'estado_cognitivo', (
      SELECT row_to_json(e) FROM public.estado_cognitivo_usuario e
      WHERE e.usuario_id = p_usuario_id
    ),

    'estado_regulacion_cruzada', (
      SELECT row_to_json(e) FROM public.estado_regulacion_cruzada e
      WHERE e.usuario_id = p_usuario_id
    ),

    'registros_carga_fisica', (
      SELECT jsonb_agg(row_to_json(r) ORDER BY r.fecha_registro DESC)
      FROM public.registros_carga_fisica r WHERE r.usuario_id = p_usuario_id
    )

  ) INTO v_result;

  RETURN jsonb_build_object('success', true, 'datos', v_result);
END;
$$;

GRANT EXECUTE ON FUNCTION public.exportar_datos_usuario(UUID) TO authenticated;

-- ── C. delete_user actualizado ─────────────────────────────────────────────

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
  SELECT u.id INTO v_admin_id FROM public.usuarios u
  WHERE u.id = auth.uid() AND u.rol = 'admin';
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Solo administradores pueden eliminar usuarios';
  END IF;

  IF v_admin_id = p_usuario_id THEN
    RAISE EXCEPTION 'No puedes eliminar tu propio usuario';
  END IF;

  SELECT email INTO v_user_email FROM public.usuarios WHERE id = p_usuario_id;
  IF v_user_email IS NULL THEN
    RAISE EXCEPTION 'Usuario no encontrado';
  END IF;

  DELETE FROM public.admin_auditoria WHERE admin_id = p_usuario_id OR entidad_id = p_usuario_id;
  DELETE FROM public.comentarios_feed WHERE usuario_id = p_usuario_id;
  DELETE FROM public.actividades_sociales WHERE usuario_id = p_usuario_id;
  DELETE FROM public.interacciones_sociales WHERE usuario_id = p_usuario_id;
  DELETE FROM public.amistades WHERE solicitante_id = p_usuario_id OR receptor_id = p_usuario_id;
  DELETE FROM public.usuario_insignias WHERE usuario_id = p_usuario_id;
  DELETE FROM public.seleccion_de_ejercicios WHERE rutina_id IN (SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id);
  DELETE FROM public.dias_rutina WHERE semana_id IN (SELECT id FROM public.semanas_rutina WHERE rutina_id IN (SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id));
  DELETE FROM public.semanas_rutina WHERE rutina_id IN (SELECT id FROM public.rutinas WHERE usuario_id = p_usuario_id);
  DELETE FROM public.progreso_de_reto WHERE usuario_id = p_usuario_id;
  DELETE FROM public.hitos_de_reto WHERE reto_id IN (SELECT id FROM public.retos WHERE usuario_id = p_usuario_id);
  DELETE FROM public.series_sesion WHERE sesion_id IN (SELECT id FROM public.sesiones_registradas WHERE usuario_id = p_usuario_id);
  DELETE FROM public.entregas_examenes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.sesiones_registradas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.rutinas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.retos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.materiales_estudio WHERE usuario_id = p_usuario_id;
  DELETE FROM public.notificaciones WHERE usuario_id = p_usuario_id;
  DELETE FROM public.horarios_academicos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.apuntes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.documentos_ia WHERE usuario_id = p_usuario_id;
  DELETE FROM public.sesiones_focus WHERE usuario_id = p_usuario_id;
  DELETE FROM public.planes_estudio WHERE usuario_id = p_usuario_id;
  DELETE FROM public.carga_academica_semanal WHERE usuario_id = p_usuario_id;
  DELETE FROM public.estado_diario_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.estado_cognitivo_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.estado_regulacion_cruzada WHERE usuario_id = p_usuario_id;
  DELETE FROM public.registros_carga_fisica WHERE usuario_id = p_usuario_id;
  DELETE FROM public.historial_peso WHERE usuario_id = p_usuario_id;
  DELETE FROM public.historial_objetivos WHERE usuario_id = p_usuario_id;
  DELETE FROM public.plan_entrenamiento_semanal WHERE usuario_id = p_usuario_id;
  DELETE FROM public.recomendaciones_pendientes WHERE usuario_id = p_usuario_id;
  DELETE FROM public.perfil_bienestar_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.perfil_academico_usuario WHERE usuario_id = p_usuario_id;
  DELETE FROM public.asignaturas_usuario_semestre WHERE usuario_id = p_usuario_id;
  DELETE FROM public.asignaturas WHERE usuario_id = p_usuario_id;
  DELETE FROM public.preferencias_notificacion WHERE usuario_id = p_usuario_id;
  DELETE FROM public.usuarios WHERE id = p_usuario_id;
  DELETE FROM auth.users WHERE id = p_usuario_id;

  RETURN jsonb_build_object('success', true, 'email', v_user_email);
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user(UUID) TO authenticated;

COMMIT;
