-- Migration: 0043_agregar_modalidad_medicion_circuito
-- Agrega tres columnas a ejercicios para soporte profesional de entrenamiento.
--   modalidad_entrenamiento: fuerza | aerobica | metabolica | movilidad
--   tipo_medicion: text[] — combinacion de valores (repeticiones, peso, tiempo, distancia, calorias)
--   es_circuito: boolean — true para ejercicios en bloques continuos

alter table public.ejercicios
  add column if not exists modalidad_entrenamiento text not null default 'fuerza',
  add column if not exists tipo_medicion text[] not null default array['repeticiones']::text[],
  add column if not exists es_circuito boolean not null default false;

comment on column public.ejercicios.modalidad_entrenamiento is 'Modalidad del ejercicio: fuerza, aerobica, metabolica o movilidad';
comment on column public.ejercicios.tipo_medicion is 'Formas de medir el rendimiento: repeticiones, peso, tiempo, distancia, calorias';
comment on column public.ejercicios.es_circuito is 'Indica si el ejercicio se entrena en circuito (bloque continuo sin series tradicionales)';

-- Actualizar la vista para incluir las nuevas columnas
drop view if exists public.v_ejercicios_completos cascade;

create or replace view public.v_ejercicios_completos
  with (security_invoker=true) as
select
  e.id,
  e.nombre,
  e.url_gif,
  e.url_preview,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
  e.finalidad,
  e.modalidad_entrenamiento,
  e.tipo_medicion,
  e.es_circuito,
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
