-- =============================================================================
-- Migración 0020: Deprecar exercise_db_id en ejercicios
-- El campo exercise_db_id (proveniente de la ExerciseDB externa) deja de ser
-- obligatorio. Nuevos ejercicios del catálogo ampliado no tendrán este ID
-- externo; se identifica únicamente por el UUID interno.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1) Eliminar el índice y la restricción UNIQUE sobre exercise_db_id
-- -----------------------------------------------------------------------------

drop index if exists public.idx_ejercicios_exercise_db_id;

do $$
declare
  constraint_name text;
begin
  select con.conname into constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  where rel.relname = 'ejercicios'
    and con.contype = 'u'
    and con.conname ilike '%exercise_db_id%';

  if constraint_name is not null then
    execute format('alter table public.ejercicios drop constraint %I', constraint_name);
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2) Permitir valores NULL en exercise_db_id
-- -----------------------------------------------------------------------------

alter table public.ejercicios
  alter column exercise_db_id drop not null;

-- -----------------------------------------------------------------------------
-- 3) Recrear la vista denormalizada (sin cambios estructurales,
--    hereda la nulabilidad de exercise_db_id)
-- -----------------------------------------------------------------------------

drop view if exists public.v_ejercicios_completos cascade;

create or replace view public.v_ejercicios_completos as
select
  e.id,
  e.exercise_db_id,
  e.nombre,
  e.url_gif,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
  e.finalidad,
  e.creado_en,
  e.actualizado_en,
  coalesce(
    (select array_agg(distinct pc.nombre)
     from public.ejercicio_parte_cuerpo epc
     join public.partes_cuerpo pc on pc.id = epc.parte_cuerpo_id
     where epc.ejercicio_id = e.id),
    '{}'
  ) as partes_cuerpo,
  coalesce(
    (select array_agg(distinct mt.nombre)
     from public.ejercicio_musculo_objetivo emo
     join public.musculos mt on mt.id = emo.musculo_id
     where emo.ejercicio_id = e.id),
    '{}'
  ) as musculos_objetivo,
  coalesce(
    (select array_agg(distinct ms.nombre)
     from public.ejercicio_musculo_secundario ems
     join public.musculos ms on ms.id = ems.musculo_id
     where ems.ejercicio_id = e.id),
    '{}'
  ) as musculos_secundarios,
  coalesce(
    (select array_agg(distinct eq.nombre)
     from public.ejercicio_equipamiento ee
     join public.equipamientos eq on eq.id = ee.equipamiento_id
     where ee.ejercicio_id = e.id),
    '{}'
  ) as equipamientos
from public.ejercicios e;

-- -----------------------------------------------------------------------------
-- 4) Restaurar grants sobre la vista recreada
-- -----------------------------------------------------------------------------

grant select on public.v_ejercicios_completos to anon, authenticated;

commit;
