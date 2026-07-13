-- ============================================================================
-- Migración 20260701000032: Fix exportar_datos_usuario — columna correcta
-- ============================================================================

BEGIN;

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

    'perfil', (SELECT jsonb_build_object(
      'id', u.id, 'email', u.email, 'nombre_completo', u.nombre_completo,
      'url_avatar', u.url_avatar, 'nivel', u.nivel, 'xp_total', u.xp_total,
      'racha_actual', u.racha_actual, 'rol', u.rol,
      'nivel_privacidad', u.nivel_privacidad, 'is_shadowbanned', u.is_shadowbanned,
      'creado_en', u.creado_en, 'actualizado_en', u.actualizado_en
    ) FROM public.usuarios u WHERE u.id = p_usuario_id),

    'perfil_bienestar', (SELECT row_to_json(p) FROM public.perfil_bienestar_usuario p WHERE p.usuario_id = p_usuario_id),
    'perfil_academico', (SELECT row_to_json(p) FROM public.perfil_academico_usuario p WHERE p.usuario_id = p_usuario_id),

    'historial_peso', (SELECT jsonb_agg(row_to_json(h) ORDER BY h.registrado_en DESC)
      FROM public.historial_peso h WHERE h.usuario_id = p_usuario_id),

    'sesiones_registradas', (SELECT jsonb_agg(row_to_json(s) ORDER BY s.completada_en DESC)
      FROM public.sesiones_registradas s WHERE s.usuario_id = p_usuario_id),

    'carga_academica_semanal', (SELECT jsonb_agg(row_to_json(c) ORDER BY c.semana_inicio DESC)
      FROM public.carga_academica_semanal c WHERE c.usuario_id = p_usuario_id),

    'horarios_academicos', (SELECT jsonb_agg(row_to_json(h) ORDER BY h.hora_inicio DESC)
      FROM public.horarios_academicos h WHERE h.usuario_id = p_usuario_id),

    'rutinas', (SELECT jsonb_agg(row_to_json(r) ORDER BY r.creado_en DESC)
      FROM public.rutinas r WHERE r.usuario_id = p_usuario_id AND r.eliminado_en IS NULL),

    'retos', (SELECT jsonb_agg(row_to_json(r) ORDER BY r.creado_en DESC)
      FROM public.retos r WHERE r.usuario_id = p_usuario_id),

    'materiales_estudio', (SELECT jsonb_agg(row_to_json(m) ORDER BY m.creado_en DESC)
      FROM public.materiales_estudio m WHERE m.usuario_id = p_usuario_id),

    'apuntes', (SELECT jsonb_agg(row_to_json(a) ORDER BY a.creado_en DESC)
      FROM public.apuntes a WHERE a.usuario_id = p_usuario_id),

    'documentos_ia', (SELECT jsonb_agg(row_to_json(d) ORDER BY d.creado_en DESC)
      FROM public.documentos_ia d WHERE d.usuario_id = p_usuario_id),

    'actividades_sociales', (SELECT jsonb_agg(row_to_json(a) ORDER BY a.creado_en DESC)
      FROM public.actividades_sociales a WHERE a.usuario_id = p_usuario_id),

    'comentarios_feed', (SELECT jsonb_agg(row_to_json(c) ORDER BY c.creado_en DESC)
      FROM public.comentarios_feed c WHERE c.usuario_id = p_usuario_id),

    'insignias', (SELECT jsonb_agg(jsonb_build_object('insignia_id', ui.insignia_id,
      'obtenida_en', ui.creado_en, 'notificada', ui.notificada) ORDER BY ui.creado_en DESC)
      FROM public.usuario_insignias ui WHERE ui.usuario_id = p_usuario_id),

    'amistades', (SELECT jsonb_agg(row_to_json(a) ORDER BY a.creado_en DESC)
      FROM public.amistades a WHERE a.solicitante_id = p_usuario_id OR a.receptor_id = p_usuario_id),

    'notificaciones', (SELECT jsonb_agg(row_to_json(n) ORDER BY n.creado_en DESC)
      FROM public.notificaciones n WHERE n.usuario_id = p_usuario_id),

    'estado_cognitivo', (SELECT row_to_json(e) FROM public.estado_cognitivo_usuario e WHERE e.usuario_id = p_usuario_id),
    'estado_regulacion_cruzada', (SELECT row_to_json(e) FROM public.estado_regulacion_cruzada e WHERE e.usuario_id = p_usuario_id),

    'registros_carga_fisica', (SELECT jsonb_agg(row_to_json(r) ORDER BY r.fecha_registro DESC)
      FROM public.registros_carga_fisica r WHERE r.usuario_id = p_usuario_id)

  ) INTO v_result;

  RETURN jsonb_build_object('success', true, 'datos', v_result);
END;
$$;
GRANT EXECUTE ON FUNCTION public.exportar_datos_usuario(UUID) TO authenticated;

COMMIT;
