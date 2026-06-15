-- ============================================================
-- Migracion: Trigger auto-completar semana al completar dias
-- Cuando todos los dias_rutina de una semana estan 'completado',
-- marca automaticamente la semana como 'completada'.
-- ============================================================

CREATE OR REPLACE FUNCTION public.marcar_semana_completada()
RETURNS TRIGGER AS $$
DECLARE
  v_total_dias INT;
  v_dias_completados INT;
BEGIN
  SELECT COUNT(*), COUNT(*) FILTER (WHERE estado = 'completado')
  INTO v_total_dias, v_dias_completados
  FROM public.dias_rutina
  WHERE semana_id = NEW.semana_id;

  IF v_dias_completados = v_total_dias AND v_total_dias > 0 THEN
    UPDATE public.semanas_rutina SET estado = 'completada'
    WHERE id = NEW.semana_id AND estado != 'completada';
  ELSIF v_dias_completados > 0 THEN
    UPDATE public.semanas_rutina SET estado = 'en_progreso'
    WHERE id = NEW.semana_id AND estado = 'pendiente';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_marcar_semana_completada ON public.dias_rutina;
CREATE TRIGGER tr_marcar_semana_completada
  AFTER UPDATE OF estado ON public.dias_rutina
  FOR EACH ROW
  WHEN (NEW.estado = 'completado')
  EXECUTE FUNCTION public.marcar_semana_completada();
