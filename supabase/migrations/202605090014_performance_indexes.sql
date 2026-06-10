-- Migration: índices de rendimiento + vista materializada de ejercicios
-- Optimiza la carga del catálogo de ejercicios eliminando subqueries correlacionadas
-- y añade índices compuestos para queries frecuentes.

-- ============================================================================
-- 1. Vista materializada de ejercicios (reemplaza v_ejercicios_completos)
--    Elimina 4 subqueries correlacionadas por cada fila.
-- ============================================================================

drop view if exists public.v_ejercicios_completos cascade;
drop materialized view if exists public.mv_ejercicios_completos;

create materialized view public.mv_ejercicios_completos as
select
  e.id,
  e.exercise_db_id,
  e.nombre,
  e.dificultad,
  e.instrucciones || array[]::text[] as instrucciones,
  e.descripcion,
  e.url_gif,
  e.creado_en,
  e.actualizado_en,
  coalesce(pc.partes_cuerpo, array[]::text[])       as partes_cuerpo,
  coalesce(mt.musculos_objetivo, array[]::text[])    as musculos_objetivo,
  coalesce(ms.musculos_secundarios, array[]::text[]) as musculos_secundarios,
  coalesce(eq.equipamientos, array[]::text[])        as equipamientos
from public.ejercicios e
left join lateral (
  select array_agg(distinct pc2.nombre order by pc2.nombre) as partes_cuerpo
  from public.ejercicio_parte_cuerpo epc
  join public.partes_cuerpo pc2 on pc2.id = epc.parte_cuerpo_id
  where epc.ejercicio_id = e.id
) pc on true
left join lateral (
  select array_agg(distinct mt2.nombre order by mt2.nombre) as musculos_objetivo
  from public.ejercicio_musculo_objetivo emo
  join public.musculos mt2 on mt2.id = emo.musculo_id
  where emo.ejercicio_id = e.id
) mt on true
left join lateral (
  select array_agg(distinct ms2.nombre order by ms2.nombre) as musculos_secundarios
  from public.ejercicio_musculo_secundario ems
  join public.musculos ms2 on ms2.id = ems.musculo_id
  where ems.ejercicio_id = e.id
) ms on true
left join lateral (
  select array_agg(distinct eq2.nombre order by eq2.nombre) as equipamientos
  from public.ejercicio_equipamiento ee
  join public.equipamientos eq2 on eq2.id = ee.equipamiento_id
  where ee.ejercicio_id = e.id
) eq on true;

-- Índices sobre la vista materializada
create unique index if not exists idx_mv_ejercicios_id
  on public.mv_ejercicios_completos (id);

create index if not exists idx_mv_ejercicios_nombre
  on public.mv_ejercicios_completos (nombre);

-- GIN para búsquedas con @> (contiene) en arrays
create index if not exists idx_mv_ejercicios_partes_gin
  on public.mv_ejercicios_completos using gin (partes_cuerpo);

create index if not exists idx_mv_ejercicios_musc_obj_gin
  on public.mv_ejercicios_completos using gin (musculos_objetivo);

create index if not exists idx_mv_ejercicios_musc_sec_gin
  on public.mv_ejercicios_completos using gin (musculos_secundarios);

create index if not exists idx_mv_ejercicios_equip_gin
  on public.mv_ejercicios_completos using gin (equipamientos);

-- GIN para búsqueda de texto completo
create index if not exists idx_mv_ejercicios_fts
  on public.mv_ejercicios_completos
  using gin (to_tsvector('spanish', coalesce(nombre, '') || ' ' || coalesce(descripcion, '')));

-- Vista de compatibilidad: reemplaza la vista original por un wrapper
-- de la materializada. Usa CREATE OR REPLACE para preservar los permisos RLS.
create or replace view public.v_ejercicios_completos as
select * from public.mv_ejercicios_completos;

-- Función para refrescar la vista materializada
create or replace function public.refrescar_mv_ejercicios()
returns void
language sql
security definer
as $$
  refresh materialized view concurrently public.mv_ejercicios_completos;
$$;

-- Trigger que refresca la vista cuando cambian los ejercicios
create or replace function public.trigger_refrescar_mv_ejercicios()
returns trigger
language plpgsql
security definer
as $$
begin
  perform public.refrescar_mv_ejercicios();
  return null;
end;
$$;

drop trigger if exists trg_refrescar_mv_ejercicios on public.ejercicios;
create trigger trg_refrescar_mv_ejercicios
  after insert or update or delete on public.ejercicios
  for each statement
  execute function public.trigger_refrescar_mv_ejercicios();

drop trigger if exists trg_refrescar_mv_junction_pc on public.ejercicio_parte_cuerpo;
create trigger trg_refrescar_mv_junction_pc
  after insert or update or delete on public.ejercicio_parte_cuerpo
  for each statement
  execute function public.trigger_refrescar_mv_ejercicios();

drop trigger if exists trg_refrescar_mv_junction_mo on public.ejercicio_musculo_objetivo;
create trigger trg_refrescar_mv_junction_mo
  after insert or update or delete on public.ejercicio_musculo_objetivo
  for each statement
  execute function public.trigger_refrescar_mv_ejercicios();

drop trigger if exists trg_refrescar_mv_junction_ms on public.ejercicio_musculo_secundario;
create trigger trg_refrescar_mv_junction_ms
  after insert or update or delete on public.ejercicio_musculo_secundario
  for each statement
  execute function public.trigger_refrescar_mv_ejercicios();

drop trigger if exists trg_refrescar_mv_junction_eq on public.ejercicio_equipamiento;
create trigger trg_refrescar_mv_junction_eq
  after insert or update or delete on public.ejercicio_equipamiento
  for each statement
  execute function public.trigger_refrescar_mv_ejercicios();


-- ============================================================================
-- 2. Índice compuesto para bienestar semanal (sesiones por usuario + fecha)
-- ============================================================================

create index if not exists idx_sesiones_usuario_completada
  on public.sesiones_registradas (usuario_id, completada_en desc);


-- ============================================================================
-- 3. Índice en ejercicios.nombre (base table, para queries que no pasan por la vista)
-- ============================================================================

create index if not exists idx_ejercicios_nombre
  on public.ejercicios (nombre);


-- ============================================================================
-- 4. Permisos: exponer la vista materializada a la API
--    Las vistas materializadas no soportan RLS. Se usa GRANT directo.
--    Los datos ya son públicos (misma procedencia que v_ejercicios_completos).
-- ============================================================================

grant select on public.mv_ejercicios_completos to anon, authenticated;
