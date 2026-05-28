-- Migration: 0028_eliminar_exercise_db_id
-- Objetivo: Eliminar completamente exercise_db_id de la base de datos:
--   1. Drop triggers y funcion de refresco de mv_ejercicios_completos
--   2. Drop materialized view mv_ejercicios_completos (legacy no usado desde 0018)
--   3. Drop columna exercise_db_id de ejercicios
--   4. Recrear v_ejercicios_completos SIN exercise_db_id

-- 1) Eliminar triggers de refresco de la materializada
drop trigger if exists trg_refrescar_mv_ejercicios on public.ejercicios;
drop trigger if exists trg_refrescar_mv_junction_pc on public.ejercicio_parte_cuerpo;
drop trigger if exists trg_refrescar_mv_junction_mo on public.ejercicio_musculo_objetivo;
drop trigger if exists trg_refrescar_mv_junction_ms on public.ejercicio_musculo_secundario;
drop trigger if exists trg_refrescar_mv_junction_eq on public.ejercicio_equipamiento;

-- 2) Eliminar funciones de refresco
drop function if exists public.trigger_refrescar_mv_ejercicios();
drop function if exists public.refrescar_mv_ejercicios();

-- 3) Eliminar vista materializada
drop materialized view if exists public.mv_ejercicios_completos;

-- 4) Eliminar columna exercise_db_id
alter table public.ejercicios
  drop column if exists exercise_db_id;

-- 5) Recrear v_ejercicios_completos sin exercise_db_id
drop view if exists public.v_ejercicios_completos cascade;

create or replace view public.v_ejercicios_completos
with (security_invoker = true)
as
select
  e.id,
  e.nombre,
  e.url_gif,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
  e.finalidad,
  e.creado_en,
  e.actualizado_en,
  coalesce(
    (select array_agg(distinct pc.nombre order by pc.nombre)
     from public.ejercicio_parte_cuerpo epc
     join public.partes_cuerpo pc on pc.id = epc.parte_cuerpo_id
     where epc.ejercicio_id = e.id),
    '{}'
  ) as partes_cuerpo,
  coalesce(
    (select array_agg(distinct mt.nombre order by mt.nombre)
     from public.ejercicio_musculo_objetivo emo
     join public.musculos mt on mt.id = emo.musculo_id
     where emo.ejercicio_id = e.id),
    '{}'
  ) as musculos_objetivo,
  coalesce(
    (select array_agg(distinct ms.nombre order by ms.nombre)
     from public.ejercicio_musculo_secundario ems
     join public.musculos ms on ms.id = ems.musculo_id
     where ems.ejercicio_id = e.id),
    '{}'
  ) as musculos_secundarios,
  coalesce(
    (select array_agg(distinct eq.nombre order by eq.nombre)
     from public.ejercicio_equipamiento ee
     join public.equipamientos eq on eq.id = ee.equipamiento_id
     where ee.ejercicio_id = e.id),
    '{}'
  ) as equipamientos
from public.ejercicios e;

grant select on public.v_ejercicios_completos to anon, authenticated;
