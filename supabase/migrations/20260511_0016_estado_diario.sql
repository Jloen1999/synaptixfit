-- =============================================================================
-- Migración 0016: Registro de estado diario del usuario (fatiga, sueño, estrés)
-- Permite que la IA adapte las recomendaciones en tiempo real según el estado
-- físico y mental del usuario cada día.
-- =============================================================================

begin;

create table if not exists public.estado_diario_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  fecha date not null default current_date,
  calidad_sueno int check (calidad_sueno between 1 and 5),
  nivel_estres int check (nivel_estres between 1 and 5),
  nivel_energia int check (nivel_energia between 1 and 5),
  dolor_muscular int check (dolor_muscular between 1 and 5),
  zonas_dolor text[] default '{}',
  listo_para_entrenar boolean default true,
  notas text,
  creado_en timestamptz not null default now(),
  unique(usuario_id, fecha)
);

-- Índice para búsqueda rápida del estado de hoy
create index if not exists idx_estado_diario_usuario_fecha
  on public.estado_diario_usuario (usuario_id, fecha desc);

-- Row Level Security
alter table public.estado_diario_usuario enable row level security;

-- Política: cada usuario ve y edita solo su propio registro
drop policy if exists estado_diario_select on public.estado_diario_usuario;
create policy estado_diario_select on public.estado_diario_usuario
  for select using (auth.uid() = usuario_id);

drop policy if exists estado_diario_insert on public.estado_diario_usuario;
create policy estado_diario_insert on public.estado_diario_usuario
  for insert with check (auth.uid() = usuario_id);

drop policy if exists estado_diario_update on public.estado_diario_usuario;
create policy estado_diario_update on public.estado_diario_usuario
  for update using (auth.uid() = usuario_id);

-- Permisos PostgREST
grant select on public.estado_diario_usuario to authenticated;
grant insert on public.estado_diario_usuario to authenticated;
grant update on public.estado_diario_usuario to authenticated;

grant all privileges on public.estado_diario_usuario to service_role;

commit;
