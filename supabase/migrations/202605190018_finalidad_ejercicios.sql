-- =============================================================================
-- Migración 0018: Finalidad del ejercicio + columnas para cardio e isometría
-- Clasifica cada ejercicio como fuerza, cardio o isométrico y añade los
-- campos necesarios en seleccion_de_ejercicios para capturar los datos
-- específicos de cada tipo.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1) Añadir columna finalidad a la tabla ejercicios
-- -----------------------------------------------------------------------------
alter table public.ejercicios
  add column if not exists finalidad text not null default 'fuerza'
    check (finalidad in ('fuerza', 'cardio', 'isometrico'));

create index if not exists idx_ejercicios_finalidad
  on public.ejercicios (finalidad);

-- -----------------------------------------------------------------------------
-- 2) Añadir columnas específicas por tipo a seleccion_de_ejercicios
--    - duracion_segundos: duración del cardio en segundos
--    - distancia_metros: distancia recorrida en metros (opcional, solo cardio)
--    - tiempo_isometrico_segundos: tiempo de sujeción en segundos (solo isométrico)
-- -----------------------------------------------------------------------------
alter table public.seleccion_de_ejercicios
  add column if not exists duracion_segundos int,
  add column if not exists distancia_metros int,
  add column if not exists tiempo_isometrico_segundos int;

-- -----------------------------------------------------------------------------
-- 3) Recrear la vista denormalizada para incluir finalidad
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
-- 4) Actualizar grants y RLS para la vista recreada
-- -----------------------------------------------------------------------------

-- Re-otorgar permisos sobre la vista
grant select on public.v_ejercicios_completos to anon, authenticated;

-- Asegurar que los grants de la tabla ejercicios sigan vigentes
-- (la columna finalidad hereda los permisos de la tabla)
grant select on public.ejercicios to anon, authenticated;
grant all privileges on public.ejercicios to service_role;

-- Los grants de seleccion_de_ejercicios se heredan de migraciones previas.
-- Aseguramos permisos para las nuevas columnas:
grant select, insert, update, delete on public.seleccion_de_ejercicios to authenticated;
grant all privileges on public.seleccion_de_ejercicios to service_role;

commit;
