-- =============================================================================
-- Migración 0019: Reparación segura del CHECK constraint de objetivo en rutinas
-- 
-- Problema: la migración 0018 pudo no aplicarse o aplicarse parcialmente,
-- dejando el constraint con valores antiguos ('fuerza', 'resistencia',
-- 'hipertrofia', 'movilidad', 'mixto') en lugar de los 7 valores actuales.
--
-- Solución: recrear la columna objetivo con el constraint correcto de forma
-- idempotente, preservando los datos existentes.
-- =============================================================================

begin;

-- Mapear cualquier valor legacy que pueda existir a los nuevos estándar
update public.rutinas set objetivo = 'ganar_masa' where objetivo = 'hipertrofia';
update public.rutinas set objetivo = 'perder_peso' where objetivo in ('perdida_de_peso', 'bajar_de_peso', 'cardio');
update public.rutinas set objetivo = 'fitness_general' where objetivo = 'general';
update public.rutinas set objetivo = 'movilidad' where objetivo = 'flexibilidad';

-- Si el constraint actual solo permite los 5 valores antiguos, la columna
-- no aceptará inserciones con los nuevos valores. La recreamos.
do $$
declare
  col_existe boolean;
begin
  -- Verificar si la columna 'objetivo' existe en 'rutinas'
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'rutinas'
      and column_name = 'objetivo'
  ) into col_existe;

  if col_existe then
    -- Renombrar columna actual para preservar datos
    alter table public.rutinas rename column objetivo to objetivo_tmp;
  end if;

  -- Crear nueva columna con el constraint corregido (7 valores)
  -- Si la columna ya tenía el constraint correcto, esta operación es segura
  -- porque la columna temporal no interfiere
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'rutinas'
      and column_name = 'objetivo'
  ) then
    alter table public.rutinas
      add column objetivo text not null default 'fuerza'
      check (objetivo in (
        'fitness_general',
        'perder_peso',
        'ganar_masa',
        'fuerza',
        'resistencia',
        'movilidad',
        'mixto'
      ));

    -- Copiar datos de la columna antigua a la nueva
    if col_existe then
      update public.rutinas set objetivo = objetivo_tmp;
      alter table public.rutinas drop column objetivo_tmp;
    end if;
  end if;
end;
$$;

commit;
