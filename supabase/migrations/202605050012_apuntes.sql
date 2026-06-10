-- Migration: apuntes con texto enriquecido (markdown)
-- RF-ACA-03: CRUD de apuntes con texto enriquecido.
-- RF-ACA-04: Visibilidad por recurso (publico, privado, solo_amigos).
-- RF-ACA-11: Permitir notas rápidas vinculadas o no a asignatura.

create table if not exists public.apuntes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  asignatura_id uuid references public.asignaturas(id) on delete set null,
  titulo text not null,
  contenido text not null default '',
  visibilidad text not null default 'privado'
    check (visibilidad in ('publico', 'privado', 'solo_amigos')),
  es_nota_rapida boolean not null default false,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_apuntes_titulo_len check (char_length(titulo) >= 1)
);

create index if not exists idx_apuntes_usuario on public.apuntes (usuario_id);
create index if not exists idx_apuntes_asignatura on public.apuntes (asignatura_id);

-- RLS: apuntes
alter table public.apuntes enable row level security;

drop policy if exists apuntes_select on public.apuntes;
create policy apuntes_select on public.apuntes
  for select
  using (
    visibilidad = 'publico'
    or usuario_id = auth.uid()
    or (
      visibilidad = 'solo_amigos'
      and exists (
        select 1 from public.amistades
        where ((solicitante_id = auth.uid() and receptor_id = usuario_id)
           or (receptor_id = auth.uid() and solicitante_id = usuario_id))
          and estado = 'aceptado'
        limit 1
      )
    )
  );

drop policy if exists apuntes_insert on public.apuntes;
create policy apuntes_insert on public.apuntes
  for insert with check (usuario_id = auth.uid());

drop policy if exists apuntes_update on public.apuntes;
create policy apuntes_update on public.apuntes
  for update using (usuario_id = auth.uid());

drop policy if exists apuntes_delete on public.apuntes;
create policy apuntes_delete on public.apuntes
  for delete using (usuario_id = auth.uid());
