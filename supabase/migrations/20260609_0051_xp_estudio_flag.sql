-- Migration: 0051_xp_estudio_flag
-- Agrega columna xp_estudio_otorgado a carga_academica_semanal
-- para evitar otorgar XP duplicado por meta de estudio semanal.

ALTER TABLE public.carga_academica_semanal
  ADD COLUMN IF NOT EXISTS xp_estudio_otorgado boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.carga_academica_semanal.xp_estudio_otorgado
  IS 'Indica si ya se otorgo XP por cumplir la meta de estudio esta semana';
