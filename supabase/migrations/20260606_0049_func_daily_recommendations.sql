-- =============================================================================
-- 0049: Función de recomendaciones diarias (para pg_cron)
--
-- Esta función puede ejecutarse vía pg_cron cada noche para:
-- 1. Detectar usuarios inactivos > 7 días → insertar recomendación de reenganche
-- 2. Detectar usuarios con fatiga alta sostenida → generar alerta
-- 3. Marcar rutinas con semanas completadas pero no finalizadas
--
-- Configuración de pg_cron (ejecutar en SQL Editor una vez):
--   SELECT cron.schedule(
--     'recomendaciones-diarias',
--     '0 2 * * *',  -- todos los días a las 2 AM
--     'SELECT generar_recomendaciones_diarias();'
--   );
-- =============================================================================

CREATE OR REPLACE FUNCTION public.generar_recomendaciones_diarias()
RETURNS SETOF public.recomendaciones_pendientes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- 1. Usuarios inactivos > 7 días
  INSERT INTO public.recomendaciones_pendientes (
    usuario_id, tipo, titulo, descripcion, datos
  )
  SELECT
    u.id,
    'descarga',
    'Volviste después de ' || (
      SELECT extract(day FROM now() - max(sr.completada_en))::int
      FROM public.sesiones_registradas sr
      WHERE sr.usuario_id = u.id
    ) || ' días',
    'Retoma con el 80% de tu carga habitual. Genera una nueva rutina adaptada a tu estado actual.',
    jsonb_build_object(
      'dias_inactivo', (
        SELECT extract(day FROM now() - max(sr2.completada_en))::int
        FROM public.sesiones_registradas sr2
        WHERE sr2.usuario_id = u.id
      ),
      'factor_carga', 0.80
    )
  FROM public.usuarios u
  WHERE (
    SELECT extract(day FROM now() - max(sr3.completada_en))::int
    FROM public.sesiones_registradas sr3
    WHERE sr3.usuario_id = u.id
  ) BETWEEN 7 AND 30
  AND NOT EXISTS (
    SELECT 1 FROM public.recomendaciones_pendientes rp
    WHERE rp.usuario_id = u.id
      AND rp.tipo = 'descarga'
      AND rp.creado_en > now() - interval '7 days'
  );

  -- 2. Usuarios con fatiga alta en últimos 3 días
  INSERT INTO public.recomendaciones_pendientes (
    usuario_id, tipo, titulo, descripcion, datos
  )
  SELECT DISTINCT ON (ed.usuario_id)
    ed.usuario_id,
    'descarga',
    'Fatiga acumulada detectada',
    'Tu puntuación de fatiga promedio es alta. Considera una semana de descarga o genera una rutina más ligera.',
    jsonb_build_object(
      'fatiga_promedio', avg_score.avg_fatiga
    )
  FROM public.estado_diario_usuario ed
  CROSS JOIN LATERAL (
    SELECT avg(
      ((6 - ed2.calidad_sueno) * 5)::int +
      ((ed2.nivel_estres - 1) * 5)::int +
      ((6 - ed2.nivel_energia) * 4)::int +
      ((ed2.dolor_muscular - 1) * 7)::int
    )::float as avg_fatiga
    FROM public.estado_diario_usuario ed2
    WHERE ed2.usuario_id = ed.usuario_id
      AND ed2.fecha >= current_date - interval '3 days'
  ) avg_score
  WHERE ed.fecha >= current_date - interval '3 days'
    AND avg_score.avg_fatiga > 50
    AND NOT EXISTS (
      SELECT 1 FROM public.recomendaciones_pendientes rp
      WHERE rp.usuario_id = ed.usuario_id
        AND rp.tipo = 'descarga'
        AND rp.creado_en > now() - interval '3 days'
    )
  ORDER BY ed.usuario_id, ed.fecha DESC;

  -- 3. Devolver las recomendaciones generadas
  RETURN QUERY
  SELECT * FROM public.recomendaciones_pendientes
  WHERE creado_en > now() - interval '5 seconds'
  ORDER BY creado_en DESC;
END;
$$;

-- Permisos
GRANT EXECUTE ON FUNCTION public.generar_recomendaciones_diarias() TO authenticated;
