-- Migration: 0044_estandarizar_finalidades_objetivo
-- Reemplaza los valores legacy de objetivo (fitness_general, perder_peso,
-- ganar_masa, fuerza, resistencia, movilidad, mixto) por las 7 finalidades
-- estandar del catalogo de ejercicios.

begin;

-- 1. Migrar datos en rutinas
do $$ begin
  update public.rutinas set objetivo = 'Hipertrofia Muscular' where objetivo = 'ganar_masa';
  update public.rutinas set objetivo = 'Hipertrofia Muscular' where objetivo = 'mixto';
  update public.rutinas set objetivo = 'Fuerza Máxima' where objetivo = 'fuerza';
  update public.rutinas set objetivo = 'Acondicionamiento Metabólico' where objetivo = 'perder_peso';
  update public.rutinas set objetivo = 'Fuerza Resistencia' where objetivo = 'resistencia';
  update public.rutinas set objetivo = 'Movilidad y Flexibilidad' where objetivo = 'movilidad';
  update public.rutinas set objetivo = 'Estabilidad y Control Motor' where objetivo = 'fitness_general';
exception when others then null;
end $$;

-- 2. Migrar datos en perfiles_bienestar
do $$ begin
  update public.perfiles_bienestar set objetivo_principal = 'Hipertrofia Muscular' where objetivo_principal = 'ganar_masa' or objetivo_principal = 'mixto';
  update public.perfiles_bienestar set objetivo_principal = 'Fuerza Máxima' where objetivo_principal = 'fuerza';
  update public.perfiles_bienestar set objetivo_principal = 'Acondicionamiento Metabólico' where objetivo_principal = 'perder_peso';
  update public.perfiles_bienestar set objetivo_principal = 'Fuerza Resistencia' where objetivo_principal = 'resistencia';
  update public.perfiles_bienestar set objetivo_principal = 'Movilidad y Flexibilidad' where objetivo_principal = 'movilidad';
  update public.perfiles_bienestar set objetivo_principal = 'Estabilidad y Control Motor' where objetivo_principal = 'fitness_general';
exception when others then null;
end $$;

-- 3. Reemplazar CHECK constraint de rutinas.objetivo con los 7 valores estandar
alter table public.rutinas
  drop constraint if exists rutinas_objetivo_check;

alter table public.rutinas
  add constraint rutinas_objetivo_check
  check (objetivo in (
    'Hipertrofia Muscular',
    'Fuerza Máxima',
    'Potencia y Explosividad',
    'Fuerza Resistencia',
    'Movilidad y Flexibilidad',
    'Estabilidad y Control Motor',
    'Acondicionamiento Metabólico'
  ));

-- 4. Asegurar columna objetivo_principal en perfiles_bienestar (sin constraint rigido)
--    La validacion se hace en el cliente (app Flutter).
alter table if exists public.perfiles_bienestar
  drop constraint if exists perfiles_bienestar_objetivo_principal_check;

commit;
