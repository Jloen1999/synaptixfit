-- ============================================================================
-- MIGRACIONES PENDIENTES — Ejecutar en Supabase SQL Editor
-- Proyecto: bimivpacrelltwfwrdnq
-- Fecha: 12/06/2026
-- Sprint 7
-- ============================================================================

-- ============================================================================
-- Migración 202606120050: Dependencias entre hitos de retos
-- ============================================================================
ALTER TABLE retos
  ADD COLUMN IF NOT EXISTS tiene_dependencias BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE hitos_de_reto
  ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'bloqueado'
    CHECK (estado IN ('bloqueado', 'disponible', 'en_progreso', 'completado')),
  ADD COLUMN IF NOT EXISTS dependencias UUID[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tipo_condicion TEXT NOT NULL DEFAULT 'AND'
    CHECK (tipo_condicion IN ('AND', 'OR', 'X_OF_Y')),
  ADD COLUMN IF NOT EXISTS condicion_n INTEGER NOT NULL DEFAULT 1
    CHECK (condicion_n >= 1);

UPDATE hitos_de_reto
SET estado = CASE
  WHEN esta_completado THEN 'completado'
  ELSE 'disponible'
END
WHERE estado = 'bloqueado';

CREATE OR REPLACE FUNCTION public.desbloquear_hitos(p_reto_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  h RECORD;
  completadas INT;
  total_deps INT;
BEGIN
  FOR h IN SELECT * FROM public.hitos_de_reto
    WHERE reto_id = p_reto_id
      AND estado = 'bloqueado'
      AND dependencias IS NOT NULL
      AND array_length(dependencias, 1) > 0
  LOOP
    total_deps := array_length(h.dependencias, 1);

    SELECT COUNT(*) INTO completadas
    FROM public.hitos_de_reto dep
    WHERE dep.id = ANY(h.dependencias) AND dep.estado = 'completado';

    IF h.tipo_condicion = 'AND' AND completadas = total_deps THEN
      UPDATE public.hitos_de_reto SET estado = 'disponible' WHERE id = h.id;
    ELSIF h.tipo_condicion = 'OR' AND completadas >= 1 THEN
      UPDATE public.hitos_de_reto SET estado = 'disponible' WHERE id = h.id;
    ELSIF h.tipo_condicion = 'X_OF_Y' AND completadas >= h.condicion_n THEN
      UPDATE public.hitos_de_reto SET estado = 'disponible' WHERE id = h.id;
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_desbloquear_hitos()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.estado = 'completado' AND (OLD.estado IS NULL OR OLD.estado != 'completado') THEN
    PERFORM public.desbloquear_hitos(NEW.reto_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hito_completado ON public.hitos_de_reto;

CREATE TRIGGER trg_hito_completado
  AFTER UPDATE OF estado ON public.hitos_de_reto
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_desbloquear_hitos();

-- ============================================================================
-- Migración 202606140001: Vista analítica semanal
-- ============================================================================
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
