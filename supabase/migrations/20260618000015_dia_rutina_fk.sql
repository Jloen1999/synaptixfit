-- =============================================================================
-- Migración 20260618000015: Vinculación Time-Blocking ↔ Días de Rutina
-- Fase 9: Vinculación Completa BD
-- =============================================================================

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS dia_rutina_id UUID
  REFERENCES public.dias_rutina(id) ON DELETE SET NULL;

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS semana_rutina_id UUID
  REFERENCES public.semanas_rutina(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_horarios_dia_rutina
  ON public.horarios_academicos(dia_rutina_id)
  WHERE dia_rutina_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_horarios_semana_rutina
  ON public.horarios_academicos(semana_rutina_id)
  WHERE semana_rutina_id IS NOT NULL;
