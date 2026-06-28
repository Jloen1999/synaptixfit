-- ============================================================
-- Migración: Fechas de semestre en el perfil académico
-- Permite almacenar las fechas absolutas de inicio y fin de clases, que el
-- flujo de generación de horarios (escaneo con IA) adjunta al patrón semanal
-- extraído del documento. Idempotente.
-- ============================================================

ALTER TABLE public.perfil_academico_usuario
  ADD COLUMN IF NOT EXISTS fecha_inicio_clases DATE,
  ADD COLUMN IF NOT EXISTS fecha_fin_clases DATE;
