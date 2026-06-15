-- ============================================================
-- Despliegue: Catálogo Académico v2 + Timeline
-- Ejecutar en SQL Editor del Dashboard de Supabase
-- https://supabase.com/dashboard/project/bimivpacrelltwfwrdnq/sql/new
-- ============================================================

-- FASE 1: Soltar FKs que apuntan al catálogo v1
alter table public.asignaturas drop constraint if exists asignaturas_catalogo_asignatura_id_fkey;
alter table public.usuario_carreras drop constraint if exists usuario_carreras_carrera_id_fkey;
delete from public.usuario_carreras;

-- FASE 2: DROP CASCADE catálogo v1
drop table if exists public.catalogo_asignaturas cascade;
drop table if exists public.catalogo_carreras cascade;
drop table if exists public.catalogo_universidades cascade;

-- FASE 3: CREATE 8 tablas v2
create table if not exists public.universidades (id uuid primary key default gen_random_uuid(), nombre text not null unique, creado_en timestamptz not null default now());
create table if not exists public.centros (id uuid primary key default gen_random_uuid(), universidad_id uuid not null references public.universidades(id) on delete cascade, nombre text not null, creado_en timestamptz not null default now(), unique(universidad_id, nombre));
create table if not exists public.carreras (id uuid primary key default gen_random_uuid(), centro_id uuid not null references public.centros(id) on delete cascade, nombre text not null, total_creditos int, total_horas int, creado_en timestamptz not null default now(), unique(centro_id, nombre));
create table if not exists public.asignaturas_catalogo (id uuid primary key default gen_random_uuid(), carrera_id uuid not null references public.carreras(id) on delete cascade, nombre text not null, curso int, semestre int, caracter text, creditos numeric(5,2), horas int, departamento text, idioma_imparticion text, url_guia_docente text, creado_en timestamptz not null default now(), unique(carrera_id, nombre));
create table if not exists public.profesores_asignatura (id uuid primary key default gen_random_uuid(), asignatura_id uuid not null references public.asignaturas_catalogo(id) on delete cascade, nombre_completo text not null, unique(asignatura_id, nombre_completo));
create table if not exists public.prerrequisitos_asignatura (id uuid primary key default gen_random_uuid(), asignatura_id uuid not null references public.asignaturas_catalogo(id) on delete cascade, nombre_asignatura text not null);
create table if not exists public.criterios_evaluacion (id uuid primary key default gen_random_uuid(), asignatura_id uuid not null references public.asignaturas_catalogo(id) on delete cascade unique, examen_final_porcentaje real default 0, evaluacion_continua_porcentaje real default 0, practicas_laboratorio_porcentaje real default 0);
create table if not exists public.bibliografia_asignatura (id uuid primary key default gen_random_uuid(), asignatura_id uuid not null references public.asignaturas_catalogo(id) on delete cascade, referencia text not null);

-- FASE 4: Índices
create index if not exists idx_centros_universidad on public.centros(universidad_id);
create index if not exists idx_carreras_centro on public.carreras(centro_id);
create index if not exists idx_asignaturas_catalogo_carrera on public.asignaturas_catalogo(carrera_id);

-- FASE 5: Reenganchar FKs
alter table public.asignaturas add column if not exists catalogo_asignatura_id uuid;
alter table public.asignaturas add constraint asignaturas_catalogo_asignatura_id_fkey foreign key (catalogo_asignatura_id) references public.asignaturas_catalogo(id) on delete set null;
alter table public.usuario_carreras add constraint usuario_carreras_carrera_id_fkey foreign key (carrera_id) references public.carreras(id) on delete cascade;

-- FASE 6: Timeline columns
alter table public.horarios_academicos add column if not exists completado boolean not null default false;
alter table public.horarios_academicos add column if not exists asistencia_registrada_en timestamptz;

-- FASE 7: RLS
alter table public.universidades enable row level security; create policy universidades_select on public.universidades for select using (true);
alter table public.centros enable row level security; create policy centros_select on public.centros for select using (true);
alter table public.carreras enable row level security; create policy carreras_select on public.carreras for select using (true);
alter table public.asignaturas_catalogo enable row level security; create policy asignaturas_catalogo_select on public.asignaturas_catalogo for select using (true);
alter table public.profesores_asignatura enable row level security; create policy profesores_asignatura_select on public.profesores_asignatura for select using (true);
alter table public.prerrequisitos_asignatura enable row level security; create policy prerrequisitos_asignatura_select on public.prerrequisitos_asignatura for select using (true);
alter table public.criterios_evaluacion enable row level security; create policy criterios_evaluacion_select on public.criterios_evaluacion for select using (true);
alter table public.bibliografia_asignatura enable row level security; create policy bibliografia_asignatura_select on public.bibliografia_asignatura for select using (true);
