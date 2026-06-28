-- =============================================================================
-- Migración 20260618000013: Tracking de XP por bloque de estudio completado
-- Fase 2: SyncHub + XP Unificado
-- =============================================================================

ALTER TABLE public.horarios_academicos
  ADD COLUMN IF NOT EXISTS xp_bloque_otorgado BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.horarios_academicos.xp_bloque_otorgado
  IS 'Indica si ya se otorgó XP al usuario por completar este bloque de estudio';

CREATE INDEX IF NOT EXISTS idx_horarios_completado_xp
  ON public.horarios_academicos(usuario_id, completado, xp_bloque_otorgado);

ALTER TABLE public.entregas_examenes
  ADD COLUMN IF NOT EXISTS xp_entrega_otorgado BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.entregas_examenes.xp_entrega_otorgado
  IS 'Indica si ya se otorgó XP al usuario por completar esta entrega';
