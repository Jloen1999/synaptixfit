-- =============================================================================
-- Migración 20260618000014: Vinculación Time-Blocking ↔ Retos
-- Fase 2: SyncHub + XP Unificado
-- =============================================================================

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS reto_id UUID REFERENCES public.retos(id) ON DELETE SET NULL;

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS hito_id UUID REFERENCES public.hitos_de_reto(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_horarios_reto_id
  ON public.horarios_academicos(reto_id) WHERE reto_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_horarios_hito_id
  ON public.horarios_academicos(hito_id) WHERE hito_id IS NOT NULL;
