-- ============================================================
-- Migración 0021: Dualidad Planificación vs Ejecución Real
--
-- Renombra duracion_segundos → duracion_objetivo_segundos
-- y añade duracion_real_segundos para capturar el tiempo
-- real medido durante la sesión de entrenamiento activo.
-- ============================================================

-- 1. Renombrar columna existente (objetivo / planificado)
ALTER TABLE public.seleccion_de_ejercicios
  RENAME COLUMN duracion_segundos TO duracion_objetivo_segundos;

-- 2. Añadir columna de ejecución real
ALTER TABLE public.seleccion_de_ejercicios
  ADD COLUMN IF NOT EXISTS duracion_real_segundos INTEGER;
