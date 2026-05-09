-- Migration: planes de estudio semanales
-- RF-ACA-01: Crear, editar y eliminar planes de estudio semanales.
-- RF-ACA-02: Crear, editar y eliminar bloques de estudio con asignatura, horario y prioridad.
-- RB-12: Todo bloque debe estar vinculado a una asignatura existente y activa.

create table if not exists public.planes_estudio (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  nombre text not null,
  semana_inicio date not null,
  semana_fin date not null,
  visibilidad text not null default 'privado'
    check (visibilidad in ('publico', 'privado', 'solo_amigos')),
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_planes_fechas check (semana_fin >= semana_inicio),
  constraint ck_planes_nombre_len check (char_length(nombre) >= 2)
);

create index if not exists idx_planes_estudio_usuario on public.planes_estudio (usuario_id);
create index if not exists idx_planes_estudio_semana on public.planes_estudio (semana_inicio, semana_fin);

-- Vincula horarios/bloques a un plan de estudio
alter table public.horarios_academicos
  add column if not exists plan_estudio_id uuid
  references public.planes_estudio(id) on delete set null;

alter table public.horarios_academicos
  add column if not exists prioridad text not null default 'media'
  check (prioridad in ('alta', 'media', 'baja'));

create index if not exists idx_horarios_plan on public.horarios_academicos (plan_estudio_id);

-- RLS: planes_estudio
alter table public.planes_estudio enable row level security;

create policy planes_estudio_select on public.planes_estudio
  for select
  using (
    visibilidad = 'publico'
    or usuario_id = auth.uid()
    or (
      visibilidad = 'solo_amigos'
      and exists (
        select 1 from public.amistades
        where (solicitante_id = auth.uid() and receptor_id = usuario_id)
          or (receptor_id = auth.uid() and solicitante_id = usuario_id)
        limit 1
      )
    )
  );

create policy planes_estudio_insert on public.planes_estudio
  for insert with check (usuario_id = auth.uid());

create policy planes_estudio_update on public.planes_estudio
  for update using (usuario_id = auth.uid());

create policy planes_estudio_delete on public.planes_estudio
  for delete using (usuario_id = auth.uid());
