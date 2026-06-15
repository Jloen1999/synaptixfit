-- Migration 0008: asignaturas_usuario_semestre
-- Permite a usuarios mapear asignaturas sin temporalidad fija (semestre=0)
-- a un curso y semestre específicos.

-- 1. Tabla de mapeo (sin FK explícitas para compatibilidad local/remoto)
create table if not exists public.asignaturas_usuario_semestre (
  id            uuid primary key default gen_random_uuid(),
  usuario_id    uuid not null,
  asignatura_id uuid not null,
  curso         integer not null check (curso >= 1),
  semestre      integer not null check (semestre in (1, 2)),
  creado_en     timestamptz not null default now(),

  unique (usuario_id, asignatura_id)
);

-- 2. RLS
alter table public.asignaturas_usuario_semestre enable row level security;

create policy "Propietario: lectura"
  on public.asignaturas_usuario_semestre
  for select using (usuario_id = auth.uid());

create policy "Propietario: insert"
  on public.asignaturas_usuario_semestre
  for insert with check (usuario_id = auth.uid());

create policy "Propietario: update"
  on public.asignaturas_usuario_semestre
  for update using (usuario_id = auth.uid());

create policy "Propietario: delete"
  on public.asignaturas_usuario_semestre
  for delete using (usuario_id = auth.uid());

-- Admin bypass (es_admin existe en migration 0006)
create policy "Admin: todo"
  on public.asignaturas_usuario_semestre
  for all using (public.es_admin())
  with check (public.es_admin());
