-- =============================================================================
-- Migración 0019: Ampliar constraint de finalidad en ejercicios
-- Añade los valores 'hipertrofia', 'resistencia', 'movilidad' al check
-- existente para soportar los nuevos ejercicios del catálogo ampliado.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1) Buscar y eliminar el constraint de finalidad existente
-- -----------------------------------------------------------------------------

do $$
declare
  constraint_name text;
begin
  select con.conname into constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  where rel.relname = 'ejercicios'
    and con.contype = 'c'
    and pg_get_constraintdef(con.oid) ilike '%finalidad%';

  if constraint_name is not null then
    execute format('alter table public.ejercicios drop constraint %I', constraint_name);
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2) Recrear el constraint con los valores ampliados
-- -----------------------------------------------------------------------------

alter table public.ejercicios
  add constraint ejercicios_finalidad_check
    check (finalidad in (
      'fuerza',
      'cardio',
      'isometrico',
      'hipertrofia',
      'resistencia',
      'movilidad'
    ));

commit;
