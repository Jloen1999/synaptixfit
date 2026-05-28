-- Migration: 0032_multi_finalidad
-- Objetivo: Convertir finalidad de TEXT a TEXT[] para soportar
--           ejercicios con múltiples finalidades.
--           Ej: Burpees pueden ser [cardio, fuerza] a la vez.

-- 1) Convertir columna existente a TEXT[]
--    Primero eliminar el DEFAULT que impide la conversion automatica
alter table public.ejercicios alter column finalidad drop default;

alter table public.ejercicios
  alter column finalidad type text[] using array[finalidad]::text[];

alter table public.ejercicios alter column finalidad set default array['fuerza']::text[];

-- 2) Eliminar CHECK antiguo y poner nuevo que valide el array
alter table public.ejercicios
  drop constraint if exists ck_ejercicios_finalidad;

alter table public.ejercicios
  add constraint ck_ejercicios_finalidad
  check (finalidad <@ array['fuerza','cardio','isometrico','hipertrofia','resistencia','movilidad']::text[]);

-- 3) Recrear v_ejercicios_completos (finalidad ya es TEXT[])
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
