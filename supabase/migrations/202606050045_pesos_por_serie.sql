-- Migration: 0045_pesos_por_serie
-- Agrega columna pesos_kg (jsonb) a seleccion_de_ejercicios para
-- permitir asignar un peso diferente por cada serie.

begin;

alter table if exists public.seleccion_de_ejercicios
  add column if not exists pesos_kg jsonb;

comment on column public.seleccion_de_ejercicios.pesos_kg is
  'Arreglo JSON con el peso de cada serie, ej. [50.0, 52.5, 55.0]. '
  'Si es null, todas las series usan peso_kg.';

commit;
