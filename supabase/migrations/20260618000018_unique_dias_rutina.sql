-- =============================================================================
-- Migración 20260618000018: Constraints de integridad en dias_rutina
-- Fase 9: Vinculación Completa BD
-- =============================================================================

ALTER TABLE public.dias_rutina
  DROP CONSTRAINT IF EXISTS uq_dias_rutina_semana_dia;

ALTER TABLE public.dias_rutina
  ADD CONSTRAINT uq_dias_rutina_semana_dia
  UNIQUE (semana_id, numero_dia);

ALTER TABLE public.dias_rutina
  DROP CONSTRAINT IF EXISTS ck_dias_rutina_numero_dia;

ALTER TABLE public.dias_rutina
  ADD CONSTRAINT ck_dias_rutina_numero_dia
  CHECK (numero_dia >= 1 AND numero_dia <= 7);
