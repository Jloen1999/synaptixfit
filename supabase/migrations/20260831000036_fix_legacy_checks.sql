-- Corrige divergencias de esquema heredadas de la BD remota (creada con
-- migraciones antiguas en español que `CREATE TABLE IF NOT EXISTS` posterior
-- no sustituyó, mismo patrón que apuntes_visibilidad_fix):
--
-- 1) `planes_estudio.visibilidad` solo aceptaba 'publico'/'privado'/
--    'solo_amigos'; la app envía 'private'/'friends'/'public' → el INSERT del
--    plan fallaba SIEMPRE al guardar el lienzo (error «No se pudo guardar»).
-- 2) `horarios_academicos` conservaba el CHECK antiguo
--    `horarios_academicos_tipo_actividad_check` (clase/estudio/deporte/otro)
--    que rechazaba descanso/comida/sueno/examen/entrega/repaso; los bloques
--    de esos tipos fallaban su insert silenciosamente.

-- 1. Normalizar visibilidad existente + CHECK canónico.
UPDATE public.planes_estudio SET visibilidad = 'private' WHERE visibilidad = 'privado';
UPDATE public.planes_estudio SET visibilidad = 'public'  WHERE visibilidad = 'publico';
UPDATE public.planes_estudio SET visibilidad = 'friends' WHERE visibilidad = 'solo_amigos';

ALTER TABLE public.planes_estudio
  DROP CONSTRAINT IF EXISTS planes_estudio_visibilidad_check;
ALTER TABLE public.planes_estudio
  ADD CONSTRAINT planes_estudio_visibilidad_check
  CHECK (visibilidad IN ('private', 'friends', 'public'));
ALTER TABLE public.planes_estudio
  ALTER COLUMN visibilidad SET DEFAULT 'private';

-- 2. Eliminar el CHECK antiguo de tipos (permanece el canónico
--    ck_horarios_tipo_actividad con los 9 tipos).
ALTER TABLE public.horarios_academicos
  DROP CONSTRAINT IF EXISTS horarios_academicos_tipo_actividad_check;
