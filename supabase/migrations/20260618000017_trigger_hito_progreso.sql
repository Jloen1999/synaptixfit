-- =============================================================================
-- Migración 20260618000017: Trigger progreso de hito al completar bloque
-- Fase 9: Vinculación Completa BD
-- =============================================================================

CREATE OR REPLACE FUNCTION public.fn_actualizar_progreso_hito()
RETURNS TRIGGER AS $$
DECLARE
  total_bloques INT;
  bloques_completados INT;
  nuevo_progreso DOUBLE PRECISION;
BEGIN
  IF NEW.hito_id IS NOT NULL
     AND NEW.completado = TRUE
     AND (OLD.completado IS DISTINCT FROM NEW.completado)
  THEN
    SELECT COUNT(*) INTO total_bloques
    FROM public.horarios_academicos
    WHERE hito_id = NEW.hito_id;

    SELECT COUNT(*) INTO bloques_completados
    FROM public.horarios_academicos
    WHERE hito_id = NEW.hito_id AND completado = TRUE;

    IF total_bloques > 0 THEN
      nuevo_progreso := LEAST(
        (bloques_completados::DOUBLE PRECISION / total_bloques) * 100.0,
        100.0
      );

      UPDATE public.hitos_de_reto
      SET
        progreso_actual = nuevo_progreso,
        esta_completado = (nuevo_progreso >= 100),
        estado = CASE
          WHEN nuevo_progreso >= 100 THEN 'completado'
          WHEN nuevo_progreso > 0 THEN 'en_progreso'
          ELSE estado
        END
      WHERE id = NEW.hito_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_bloque_hito_progreso ON public.horarios_academicos;

CREATE TRIGGER trg_bloque_hito_progreso
  AFTER UPDATE OF completado ON public.horarios_academicos
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_actualizar_progreso_hito();
