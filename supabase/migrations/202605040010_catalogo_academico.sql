-- Migration: catálogo académico (universidades, carreras, asignaturas)
-- Desnormaliza grados.json en tablas relacionales para consultas eficientes.
-- RB: las tablas de catálogo son de solo lectura pública.

create table if not exists public.catalogo_universidades (
  id uuid primary key default gen_random_uuid(),
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

create table if not exists public.catalogo_carreras (
  id uuid primary key default gen_random_uuid(),
  universidad_id uuid not null references public.catalogo_universidades(id) on delete cascade,
  nombre text not null,
  creado_en timestamptz not null default now(),
  unique(universidad_id, nombre)
);

create table if not exists public.catalogo_asignaturas (
  id uuid primary key default gen_random_uuid(),
  carrera_id uuid not null references public.catalogo_carreras(id) on delete cascade,
  nombre text not null,
  curso int,
  semestre int,
  caracter text,
  creditos numeric(4,1),
  creado_en timestamptz not null default now(),
  unique(carrera_id, nombre)
);

create index if not exists idx_catalogo_carreras_univ on public.catalogo_carreras (universidad_id);
create index if not exists idx_catalogo_asignaturas_carrera on public.catalogo_asignaturas (carrera_id);

-- FK opcional: permite vincular una asignatura del usuario al catálogo
alter table public.asignaturas
  add column if not exists catalogo_asignatura_id uuid
  references public.catalogo_asignaturas(id) on delete set null;

-- RLS: catálogo público, solo lectura
alter table public.catalogo_universidades enable row level security;
alter table public.catalogo_carreras enable row level security;
alter table public.catalogo_asignaturas enable row level security;

drop policy if exists catalogo_universidades_select on public.catalogo_universidades;
create policy catalogo_universidades_select on public.catalogo_universidades
  for select using (true);

drop policy if exists catalogo_carreras_select on public.catalogo_carreras;
create policy catalogo_carreras_select on public.catalogo_carreras
  for select using (true);

drop policy if exists catalogo_asignaturas_select on public.catalogo_asignaturas;
create policy catalogo_asignaturas_select on public.catalogo_asignaturas
  for select using (true);
