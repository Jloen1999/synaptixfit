-- ============================================================================
-- Migración 202606120050: Dependencias entre hitos de retos (Sprint 7)
-- ============================================================================

-- 1. Añadir columna de dependencias a retos (denormalizada para filtros rápidos)
ALTER TABLE retos
  ADD COLUMN IF NOT EXISTS tiene_dependencias BOOLEAN NOT NULL DEFAULT false;

-- 2. Añadir columnas de dependencias y estados a hitos_de_reto
ALTER TABLE hitos_de_reto
  ADD COLUMN IF NOT EXISTS estado TEXT NOT NULL DEFAULT 'bloqueado'
    CHECK (estado IN ('bloqueado', 'disponible', 'en_progreso', 'completado')),
  ADD COLUMN IF NOT EXISTS dependencias UUID[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS tipo_condicion TEXT NOT NULL DEFAULT 'AND'
    CHECK (tipo_condicion IN ('AND', 'OR', 'X_OF_Y')),
  ADD COLUMN IF NOT EXISTS condicion_n INTEGER NOT NULL DEFAULT 1
    CHECK (condicion_n >= 1);

-- 3. Migrar hitos existentes: si ya completado → 'completado', si no → 'disponible' (sin dependencias previas)
UPDATE hitos_de_reto
SET estado = CASE
  WHEN esta_completado THEN 'completado'
  ELSE 'disponible'
END
WHERE estado = 'bloqueado';

-- 4. Función para desbloquear hitos cuyas dependencias están satisfechas
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

-- 5. Trigger: al completar un hito, desbloquear los que dependen de él
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
