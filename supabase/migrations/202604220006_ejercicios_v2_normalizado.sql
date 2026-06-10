-- =============================================================================
-- Migración 0006: Modelo normalizado de ejercicios (ExerciseDB en español)
-- Reemplaza la tabla plana 'ejercicios' por un modelo 3NF con catálogos
-- y relaciones N:M para músculos, partes del cuerpo y equipamientos.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 1) Tablas de catálogo (datos maestros, acceso público de lectura)
-- -----------------------------------------------------------------------------

create table if not exists public.partes_cuerpo (
  id serial primary key,
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

create table if not exists public.musculos (
  id serial primary key,
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

create table if not exists public.equipamientos (
  id serial primary key,
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 2) Eliminar la tabla ejercicios antigua y sus dependencias
-- -----------------------------------------------------------------------------

-- Eliminar triggers y policies de la tabla antigua
drop trigger if exists trg_ejercicios_actualizado_en on public.ejercicios;
drop policy if exists ejercicios_select on public.ejercicios;

-- Eliminar índices antiguos
drop index if exists idx_ejercicios_grupo_muscular;
drop index if exists idx_ejercicios_equipamiento;
drop index if exists idx_ejercicios_dificultad;
drop index if exists idx_ejercicios_id_wger;
drop index if exists idx_ejercicios_fts;

-- Eliminar FK de seleccion_de_ejercicios antes de recrear la tabla
alter table if exists public.seleccion_de_ejercicios
  drop constraint if exists seleccion_de_ejercicios_ejercicio_id_fkey;

-- Recrear la tabla ejercicios con el nuevo esquema
drop table if exists public.ejercicios cascade;

create table if not exists public.ejercicios (
  id uuid primary key default gen_random_uuid(),
  exercise_db_id text unique,
  nombre text not null,
  url_gif text,
  instrucciones text[] not null default '{}',
  dificultad text not null default 'medio',
  descripcion text,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_ejercicios_nombre_len check (char_length(nombre) >= 2),
  constraint ck_ejercicios_dificultad check (dificultad in ('facil', 'medio', 'dificil'))
);

-- Índices para la tabla ejercicios
create index if not exists idx_ejercicios_exercise_db_id on public.ejercicios (exercise_db_id);
create index if not exists idx_ejercicios_dificultad on public.ejercicios (dificultad);
create index if not exists idx_ejercicios_fts on public.ejercicios using gin (
  to_tsvector('spanish', coalesce(nombre, '') || ' ' || coalesce(descripcion, ''))
);

-- Trigger de actualización
create trigger trg_ejercicios_actualizado_en
before update on public.ejercicios
for each row
execute function public.fn_set_actualizado_en();

-- Restaurar la FK de seleccion_de_ejercicios
alter table if exists public.seleccion_de_ejercicios
  drop constraint if exists seleccion_de_ejercicios_ejercicio_id_fkey;
alter table public.seleccion_de_ejercicios
  add constraint seleccion_de_ejercicios_ejercicio_id_fkey
  foreign key (ejercicio_id) references public.ejercicios(id) on delete restrict;

-- -----------------------------------------------------------------------------
-- 3) Tablas de relación N:M
-- -----------------------------------------------------------------------------

-- Ejercicio ↔ Músculo objetivo
create table if not exists public.ejercicio_musculo_objetivo (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  musculo_id int not null references public.musculos(id) on delete cascade,
  primary key (ejercicio_id, musculo_id)
);

-- Ejercicio ↔ Músculo secundario
create table if not exists public.ejercicio_musculo_secundario (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  musculo_id int not null references public.musculos(id) on delete cascade,
  primary key (ejercicio_id, musculo_id)
);

-- Ejercicio ↔ Parte del cuerpo
create table if not exists public.ejercicio_parte_cuerpo (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  parte_cuerpo_id int not null references public.partes_cuerpo(id) on delete cascade,
  primary key (ejercicio_id, parte_cuerpo_id)
);

-- Ejercicio ↔ Equipamiento
create table if not exists public.ejercicio_equipamiento (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  equipamiento_id int not null references public.equipamientos(id) on delete cascade,
  primary key (ejercicio_id, equipamiento_id)
);

-- Índices para JOINs rápidos
create index if not exists idx_emo_musculo on public.ejercicio_musculo_objetivo (musculo_id);
create index if not exists idx_ems_musculo on public.ejercicio_musculo_secundario (musculo_id);
create index if not exists idx_epc_parte on public.ejercicio_parte_cuerpo (parte_cuerpo_id);
create index if not exists idx_ee_equip on public.ejercicio_equipamiento (equipamiento_id);

-- -----------------------------------------------------------------------------
-- 4) Vista denormalizada para consultas rápidas desde el frontend
-- -----------------------------------------------------------------------------

create or replace view public.v_ejercicios_completos as
select
  e.id,
  e.exercise_db_id,
  e.nombre,
  e.url_gif,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
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
-- 5) Row Level Security
-- -----------------------------------------------------------------------------

-- Catálogos: lectura pública
alter table public.partes_cuerpo enable row level security;
alter table public.musculos enable row level security;
alter table public.equipamientos enable row level security;

drop policy if exists partes_cuerpo_select on public.partes_cuerpo;
create policy partes_cuerpo_select on public.partes_cuerpo
for select using (true);

drop policy if exists musculos_select on public.musculos;
create policy musculos_select on public.musculos
for select using (true);

drop policy if exists equipamientos_select on public.equipamientos;
create policy equipamientos_select on public.equipamientos
for select using (true);

-- Ejercicios: lectura pública
alter table public.ejercicios enable row level security;
drop policy if exists ejercicios_select on public.ejercicios;
create policy ejercicios_select on public.ejercicios
for select using (true);

-- Tablas de relación: lectura pública
alter table public.ejercicio_musculo_objetivo enable row level security;
alter table public.ejercicio_musculo_secundario enable row level security;
alter table public.ejercicio_parte_cuerpo enable row level security;
alter table public.ejercicio_equipamiento enable row level security;

drop policy if exists emo_select on public.ejercicio_musculo_objetivo;
create policy emo_select on public.ejercicio_musculo_objetivo
for select using (true);

drop policy if exists ems_select on public.ejercicio_musculo_secundario;
create policy ems_select on public.ejercicio_musculo_secundario
for select using (true);

drop policy if exists epc_select on public.ejercicio_parte_cuerpo;
create policy epc_select on public.ejercicio_parte_cuerpo
for select using (true);

drop policy if exists ee_select on public.ejercicio_equipamiento;
create policy ee_select on public.ejercicio_equipamiento
for select using (true);

-- -----------------------------------------------------------------------------
-- 6) Permisos PostgREST (para evitar 42501)
-- -----------------------------------------------------------------------------

grant select on public.partes_cuerpo to anon, authenticated;
grant select on public.musculos to anon, authenticated;
grant select on public.equipamientos to anon, authenticated;
grant select on public.ejercicios to anon, authenticated;
grant select on public.ejercicio_musculo_objetivo to anon, authenticated;
grant select on public.ejercicio_musculo_secundario to anon, authenticated;
grant select on public.ejercicio_parte_cuerpo to anon, authenticated;
grant select on public.ejercicio_equipamiento to anon, authenticated;
grant select on public.v_ejercicios_completos to anon, authenticated;

grant all privileges on public.partes_cuerpo to service_role;
grant all privileges on public.musculos to service_role;
grant all privileges on public.equipamientos to service_role;
grant all privileges on public.ejercicios to service_role;
grant all privileges on public.ejercicio_musculo_objetivo to service_role;
grant all privileges on public.ejercicio_musculo_secundario to service_role;
grant all privileges on public.ejercicio_parte_cuerpo to service_role;
grant all privileges on public.ejercicio_equipamiento to service_role;

-- Grants para insert de datos de catálogo vía service_role
grant usage, select on sequence public.partes_cuerpo_id_seq to service_role;
grant usage, select on sequence public.musculos_id_seq to service_role;
grant usage, select on sequence public.equipamientos_id_seq to service_role;

commit;
