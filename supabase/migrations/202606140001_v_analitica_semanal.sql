-- ============================================================
-- Migracion: Vista agregada semanal de sesiones de entrenamiento
-- Agrupa sesiones_registradas por usuario y semana (lunes).
-- ============================================================

CREATE OR REPLACE VIEW public.v_analitica_semanal AS
SELECT
  usuario_id,
  date_trunc('week', completada_en)::date AS semana_inicio,
  COUNT(*)::int AS sesiones,
  COALESCE(ROUND(AVG(rpe)::numeric, 1), 0) AS rpe_promedio,
  COALESCE(SUM(duracion_minutos), 0)::int AS minutos_totales,
  COALESCE(SUM(calorias_quemadas), 0)::int AS calorias_totales
FROM public.sesiones_registradas
WHERE completada_en IS NOT NULL
GROUP BY usuario_id, date_trunc('week', completada_en)::date
ORDER BY usuario_id, semana_inicio DESC;

-- La vista no necesita RLS porque hereda los permisos de las tablas base.
-- Las consultas desde el cliente se filtran por usuario_id autenticado.
