-- Correcciones de planificación y vinculación de retos.
--
-- 1. `horarios_academicos.asignatura_id` pasa a NULLABLE: los bloques de
--    deporte, descanso, retos fitness, etc. no tienen asignatura y su insert
--    fallaba silenciosamente por la restricción NOT NULL, por lo que esos
--    bloques desaparecían al recargar el plan.
-- 2. `retos.entidad_vinculada_tipo` / `hitos_de_reto.entidad_vinculada_tipo`
--    aceptan ahora 'bloque' para poder vincular un reto a un bloque de
--    estudio del calendario (además de examen/entrega).

ALTER TABLE public.horarios_academicos
  ALTER COLUMN asignatura_id DROP NOT NULL;

ALTER TABLE public.retos DROP CONSTRAINT IF EXISTS ck_retos_entidad_tipo;
ALTER TABLE public.retos
  ADD CONSTRAINT ck_retos_entidad_tipo
  CHECK (entidad_vinculada_tipo IS NULL
    OR entidad_vinculada_tipo = ANY (ARRAY['examen'::text, 'entrega'::text, 'bloque'::text]));

ALTER TABLE public.hitos_de_reto DROP CONSTRAINT IF EXISTS ck_hitos_entidad_tipo;
ALTER TABLE public.hitos_de_reto
  ADD CONSTRAINT ck_hitos_entidad_tipo
  CHECK (entidad_vinculada_tipo IS NULL
    OR entidad_vinculada_tipo = ANY (ARRAY['examen'::text, 'entrega'::text, 'bloque'::text]));
