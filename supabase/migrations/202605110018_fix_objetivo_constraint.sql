-- =============================================================================
-- Migración 0018: Corrige constraint de objetivo en rutinas
-- La columna objetivo tiene un CHECK inline que no se puede droppear por nombre.
-- Solución: recrear la columna preservando los datos.
-- =============================================================================

begin;

-- Mapear valores legacy a los nuevos estándar
update public.rutinas
  set objetivo = 'ganar_masa'
  where objetivo = 'hipertrofia';

-- Renombrar columna actual para preservar datos (solo si no se ha renombrado antes)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'rutinas'
      and column_name = 'objetivo'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'rutinas'
      and column_name = 'objetivo_old'
  ) then
    alter table public.rutinas rename column objetivo to objetivo_old;
  end if;
end $$;

-- Crear nueva columna con el constraint corregido (7 valores válidos)
alter table public.rutinas
  add column if not exists objetivo text not null default 'fuerza'
  check (objetivo in (
    'fitness_general',
    'perder_peso',
    'ganar_masa',
    'fuerza',
    'resistencia',
    'movilidad',
    'mixto'
  ));

-- Copiar datos de la columna antigua a la nueva (solo si objetivo_old existe)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'rutinas'
      and column_name = 'objetivo_old'
  ) then
    update public.rutinas set objetivo = objetivo_old;
  end if;
end $$;

-- Eliminar columna antigua (y su constraint inline)
alter table public.rutinas drop column if exists objetivo_old;

commit;
