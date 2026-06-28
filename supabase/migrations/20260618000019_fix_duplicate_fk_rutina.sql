-- =============================================================================
-- Migración 20260618000019: Eliminar FK duplicada en rutina_id
-- Fix: PostgREST error PGRST201 — two FK constraints on same column
-- =============================================================================

ALTER TABLE public.horarios_academicos
  DROP CONSTRAINT IF EXISTS horarios_academicos_rutina_id_fkey;
