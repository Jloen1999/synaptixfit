-- Migration: usuario_carreras (M:N)
-- Permite que un usuario tenga múltiples carreras asociadas.
-- Al añadir una carrera, se sincronizan automáticamente sus asignaturas.

create table if not exists public.usuario_carreras (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  carrera_id uuid not null references public.catalogo_carreras(id) on delete cascade,
  creado_en timestamptz not null default now(),
  unique(usuario_id, carrera_id)
);

create index if not exists idx_usuario_carreras_usuario on public.usuario_carreras (usuario_id);

alter table public.usuario_carreras enable row level security;

create policy usuario_carreras_select on public.usuario_carreras
  for select using (usuario_id = auth.uid());

create policy usuario_carreras_insert on public.usuario_carreras
  for insert with check (usuario_id = auth.uid());

create policy usuario_carreras_delete on public.usuario_carreras
  for delete using (usuario_id = auth.uid());
