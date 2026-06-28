-- =============================================================================
-- Migración 20260618000016: Convertir rutina_id en FK real
-- Fase 9: Vinculación Completa BD
-- =============================================================================

-- Asegurar que no haya valores huérfanos antes de crear la FK
DELETE FROM public.horarios_academicos
WHERE rutina_id IS NOT NULL
  AND rutina_id NOT IN (SELECT id FROM public.rutinas);

ALTER TABLE public.horarios_academicos
  DROP CONSTRAINT IF EXISTS fk_horarios_rutina;

ALTER TABLE public.horarios_academicos
  ADD CONSTRAINT fk_horarios_rutina
  FOREIGN KEY (rutina_id) REFERENCES public.rutinas(id) ON DELETE SET NULL;
