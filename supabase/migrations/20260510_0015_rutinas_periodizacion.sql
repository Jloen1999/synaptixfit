-- Migration: rutinas con periodización semanal y diaria
-- Añade semanas, días, peso por ejercicio, y registro de series por sesión.

-- ============================================================================
-- 1. Nuevas columnas en rutinas
-- ============================================================================
alter table public.rutinas
  add column if not exists duracion_semanas int not null default 1,
  add column if not exists objetivo text not null default 'fuerza'
    check (objetivo in ('fuerza', 'resistencia', 'hipertrofia', 'movilidad', 'mixto')),
  add column if not exists estado text not null default 'activo'
    check (estado in ('activo', 'pausado', 'completado', 'archivado'));

-- ============================================================================
-- 2. semanas_rutina — una fila por cada semana de la rutina
-- ============================================================================
create table if not exists public.semanas_rutina (
  id uuid primary key default gen_random_uuid(),
  rutina_id uuid not null references public.rutinas(id) on delete cascade,
  numero_semana int not null,
  nombre text not null default '',
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'en_progreso', 'completada')),
  creado_en timestamptz not null default now(),
  unique(rutina_id, numero_semana)
);

create index if not exists idx_semanas_rutina on public.semanas_rutina (rutina_id);

-- ============================================================================
-- 3. dias_rutina — un día de entrenamiento dentro de una semana
-- ============================================================================
create table if not exists public.dias_rutina (
  id uuid primary key default gen_random_uuid(),
  semana_id uuid not null references public.semanas_rutina(id) on delete cascade,
  numero_dia int not null,
  nombre text not null default '',
  estado text not null default 'pendiente'
    check (estado in ('pendiente', 'en_progreso', 'completado')),
  creado_en timestamptz not null default now(),
  unique(semana_id, numero_dia)
);

create index if not exists idx_dias_semana on public.dias_rutina (semana_id);

-- ============================================================================
-- 4. Nuevas columnas en seleccion_de_ejercicios (vinculación a día + peso)
-- ============================================================================
alter table public.seleccion_de_ejercicios
  add column if not exists dia_id uuid references public.dias_rutina(id) on delete cascade,
  add column if not exists peso_kg double precision;

create index if not exists idx_seleccion_dia on public.seleccion_de_ejercicios (dia_id);

-- Eliminar constraints antiguos que impiden mismo ejercicio/orden en distintos días
-- 1) UNIQUE(rutina_id, ejercicio_id, indice_orden) — impide mismo ejercicio en misma posición
-- 2) UNIQUE(rutina_id, indice_orden) — impide mismo índice en la misma rutina
-- Ambos chocan con la periodización donde ejercicios/índices pueden repetirse en días distintos.
do $$
begin
  if exists (select 1 from pg_constraint
    where conrelid = 'public.seleccion_de_ejercicios'::regclass
    and conname = 'seleccion_de_ejercicios_rutina_id_ejercicio_id_indice_orden_key')
  then
    alter table public.seleccion_de_ejercicios
      drop constraint seleccion_de_ejercicios_rutina_id_ejercicio_id_indice_orden_key;
  end if;

  if exists (select 1 from pg_constraint
    where conrelid = 'public.seleccion_de_ejercicios'::regclass
    and conname = 'seleccion_de_ejercicios_rutina_id_indice_orden_key')
  then
    alter table public.seleccion_de_ejercicios
      drop constraint seleccion_de_ejercicios_rutina_id_indice_orden_key;
  end if;
end $$;

-- Nuevo índice único: mismo ejercicio no se repite en el mismo día y orden,
-- pero SÍ puede estar en días distintos sin conflicto.
drop index if exists idx_seleccion_dia_ej_orden;
create unique index idx_seleccion_dia_ej_orden
  on public.seleccion_de_ejercicios (rutina_id, coalesce(dia_id, id), ejercicio_id, indice_orden);

-- ============================================================================
-- 5. Nuevas columnas en sesiones_registradas
-- ============================================================================
alter table public.sesiones_registradas
  add column if not exists dia_id uuid references public.dias_rutina(id) on delete set null,
  add column if not exists tipo text not null default 'libre'
    check (tipo in ('libre', 'rutina', 'semanal'));

create index if not exists idx_sesiones_dia on public.sesiones_registradas (dia_id);

-- ============================================================================
-- 6. series_sesion — registro real de cada serie ejecutada
-- ============================================================================
create table if not exists public.series_sesion (
  id uuid primary key default gen_random_uuid(),
  sesion_id uuid not null references public.sesiones_registradas(id) on delete cascade,
  seleccion_id uuid references public.seleccion_de_ejercicios(id) on delete set null,
  numero_serie int not null,
  repeticiones_realizadas int,
  peso_kg double precision,
  completada boolean not null default false,
  creado_en timestamptz not null default now()
);

create index if not exists idx_series_sesion on public.series_sesion (sesion_id);

-- ============================================================================
-- 7. RLS para las nuevas tablas (herencia del propietario vía rutina)
-- ============================================================================
alter table public.semanas_rutina enable row level security;
alter table public.dias_rutina enable row level security;
alter table public.series_sesion enable row level security;

-- semanas_rutina: solo el dueño de la rutina padre
drop policy if exists semanas_select on public.semanas_rutina;
create policy semanas_select on public.semanas_rutina for select using (
  exists (select 1 from public.rutinas r
    where r.id = rutina_id and (
      r.visibilidad != 'private' or r.usuario_id = auth.uid()
    ))
);
drop policy if exists semanas_modificar on public.semanas_rutina;
create policy semanas_modificar on public.semanas_rutina for all using (
  exists (select 1 from public.rutinas r
    where r.id = rutina_id and r.usuario_id = auth.uid())
);

-- dias_rutina: solo el dueño de la rutina padre
drop policy if exists dias_select on public.dias_rutina;
create policy dias_select on public.dias_rutina for select using (
  exists (select 1 from public.semanas_rutina s
    join public.rutinas r on r.id = s.rutina_id
    where s.id = semana_id and (
      r.visibilidad != 'private' or r.usuario_id = auth.uid()
    ))
);
drop policy if exists dias_modificar on public.dias_rutina;
create policy dias_modificar on public.dias_rutina for all using (
  exists (select 1 from public.semanas_rutina s
    join public.rutinas r on r.id = s.rutina_id
    where s.id = semana_id and r.usuario_id = auth.uid())
);

-- series_sesion: solo el dueño de la sesión padre
drop policy if exists series_select on public.series_sesion;
create policy series_select on public.series_sesion for select using (
  exists (select 1 from public.sesiones_registradas s
    where s.id = sesion_id and s.usuario_id = auth.uid())
);
drop policy if exists series_modificar on public.series_sesion;
create policy series_modificar on public.series_sesion for all using (
  exists (select 1 from public.sesiones_registradas s
    where s.id = sesion_id and s.usuario_id = auth.uid())
);
