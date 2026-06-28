-- =============================================================================
-- Migración 20260618000012: Tracking de XP por planificación semanal
-- Fase 2: SyncHub + XP Unificado
-- =============================================================================

ALTER TABLE public.planes_estudio
  ADD COLUMN IF NOT EXISTS xp_planificacion_otorgado BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.planes_estudio.xp_planificacion_otorgado
  IS 'Indica si ya se otorgó XP al usuario por planificar esta semana';
