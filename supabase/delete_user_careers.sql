-- =============================================================================
-- Script para limpiar carreras y universidades de los usuarios
-- (No elimina el catálogo público, solo las asignaciones de los usuarios)
-- =============================================================================

BEGIN;

-- 1. Eliminar la relación M:N de las carreras de todos los usuarios
DELETE FROM public.usuario_carreras;

-- 2. Limpiar los campos universidad y carrera en el perfil académico de los usuarios
UPDATE public.perfil_academico_usuario
SET 
  universidad = NULL,
  carrera = NULL,
  actualizado_en = now();

COMMIT;
