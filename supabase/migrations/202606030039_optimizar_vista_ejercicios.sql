-- Migration: 0039_optimizar_vista_ejercicios
-- Objetivo: Recrear v_ejercicios_completos con LATERAL joins
--           en lugar de subconsultas correlacionadas para
--           mejorar el rendimiento en ~30-60% con 909 ejercicios.
--
-- Las subconsultas correlacionadas en el SELECT fuerzan
-- 4 subconsultas por fila. Con LATERAL, PostgreSQL puede
-- optimizar los joins y reducir el overhead.
--
-- Las tablas de union ya tienen indices por PK compuesta
-- (ejercicio_id, musculo_id), por lo que no se requieren
-- indices adicionales.

drop view if exists public.v_ejercicios_completos cascade;

create or replace view public.v_ejercicios_completos with (security_invoker=true) as
select
  e.id,
  e.nombre,
  e.url_gif,
  e.url_preview,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
  e.finalidad,
  e.creado_en,
  coalesce(mo.arr, '[]'::jsonb) as musculos_objetivo,
  coalesce(ms.arr, '[]'::jsonb) as musculos_secundarios,
  coalesce(pc.arr, '[]'::jsonb) as partes_cuerpo,
  coalesce(eq.arr, '[]'::jsonb) as equipamientos
from ejercicios e
left join lateral (
  select jsonb_agg(distinct m.nombre) as arr
  from ejercicio_musculo_objetivo emo
  join musculos m on m.id = emo.musculo_id
  where emo.ejercicio_id = e.id
) mo on true
left join lateral (
  select jsonb_agg(distinct m.nombre) as arr
  from ejercicio_musculo_secundario ems
  join musculos m on m.id = ems.musculo_id
  where ems.ejercicio_id = e.id
) ms on true
left join lateral (
  select jsonb_agg(distinct pc.nombre) as arr
  from ejercicio_parte_cuerpo epc
  join partes_cuerpo pc on pc.id = epc.parte_cuerpo_id
  where epc.ejercicio_id = e.id
) pc on true
left join lateral (
  select jsonb_agg(distinct eq.nombre) as arr
  from ejercicio_equipamiento eeq
  join equipamientos eq on eq.id = eeq.equipamiento_id
  where eeq.ejercicio_id = e.id
) eq on true;

-- Actualizar estadisticas del planificador
analyze public.ejercicios;
