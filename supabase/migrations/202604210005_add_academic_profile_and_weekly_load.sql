-- Migration: Extender modelo academico para personalizacion
-- Fecha: 2026-04-21
-- Incluye:
-- 1) perfil_academico_usuario
-- 2) extension de asignaturas
-- 3) carga_academica_semanal
-- 4) RLS y permisos para evitar errores de acceso

begin;

-- -----------------------------------------------------------------------------
-- 1) Extender asignaturas
-- -----------------------------------------------------------------------------
alter table if exists public.asignaturas
  add column if not exists dificultad_percibida int not null default 3,
  add column if not exists creditos int not null default 3,
  add column if not exists prioridad text not null default 'media',
  add column if not exists proxima_evaluacion timestamptz;

create index if not exists idx_asignaturas_proxima_evaluacion
  on public.asignaturas (proxima_evaluacion);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ck_asignaturas_dificultad'
  ) then
    alter table public.asignaturas
      add constraint ck_asignaturas_dificultad
      check (dificultad_percibida between 1 and 5);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'ck_asignaturas_creditos'
  ) then
    alter table public.asignaturas
      add constraint ck_asignaturas_creditos
      check (creditos between 1 and 30);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'ck_asignaturas_prioridad'
  ) then
    alter table public.asignaturas
      add constraint ck_asignaturas_prioridad
      check (prioridad in ('baja', 'media', 'alta'));
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- 2) perfil_academico_usuario
-- -----------------------------------------------------------------------------
create table if not exists public.perfil_academico_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null unique references public.usuarios(id) on delete cascade,
  universidad text,
  carrera text,
  semestre_actual int not null default 1,
  modalidad text not null default 'presencial',
  creditos_semestre_actual int not null default 20,
  horas_objetivo_estudio_semana int not null default 14,
  promedio_objetivo double precision,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_perfil_acad_semestre check (semestre_actual between 1 and 20),
  constraint ck_perfil_acad_modalidad check (modalidad in ('presencial', 'hibrida', 'virtual')),
  constraint ck_perfil_acad_creditos check (creditos_semestre_actual between 1 and 60),
  constraint ck_perfil_acad_horas check (horas_objetivo_estudio_semana between 0 and 80),
  constraint ck_perfil_acad_promedio check (
    promedio_objetivo is null or (promedio_objetivo between 0 and 5)
  )
);

create index if not exists idx_perfil_academico_usuario_id
  on public.perfil_academico_usuario (usuario_id);

drop trigger if exists trg_perfil_academico_actualizado_en on public.perfil_academico_usuario;
create trigger trg_perfil_academico_actualizado_en
before update on public.perfil_academico_usuario
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 3) carga_academica_semanal
-- -----------------------------------------------------------------------------
create table if not exists public.carga_academica_semanal (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  semana_inicio date not null,
  horas_estudio_planeadas int not null default 0,
  horas_estudio_reales int not null default 0,
  evaluaciones_semana int not null default 0,
  entregas_semana int not null default 0,
  nivel_estres int not null default 5,
  horas_sueno_promedio double precision not null default 7,
  notas text,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_carga_horas_planeadas check (horas_estudio_planeadas between 0 and 120),
  constraint ck_carga_horas_reales check (horas_estudio_reales between 0 and 120),
  constraint ck_carga_evaluaciones check (evaluaciones_semana between 0 and 20),
  constraint ck_carga_entregas check (entregas_semana between 0 and 20),
  constraint ck_carga_estres check (nivel_estres between 1 and 10),
  constraint ck_carga_sueno check (horas_sueno_promedio between 0 and 14),
  unique (usuario_id, semana_inicio)
);

create index if not exists idx_carga_academica_usuario_id
  on public.carga_academica_semanal (usuario_id);
create index if not exists idx_carga_academica_semana
  on public.carga_academica_semanal (semana_inicio desc);

drop trigger if exists trg_carga_academica_actualizado_en on public.carga_academica_semanal;
create trigger trg_carga_academica_actualizado_en
before update on public.carga_academica_semanal
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 4) RLS para tablas nuevas
-- -----------------------------------------------------------------------------
alter table public.perfil_academico_usuario enable row level security;
alter table public.carga_academica_semanal enable row level security;

drop policy if exists perfil_academico_select on public.perfil_academico_usuario;
create policy perfil_academico_select on public.perfil_academico_usuario
for select using (auth.uid() = usuario_id);

drop policy if exists perfil_academico_insert on public.perfil_academico_usuario;
create policy perfil_academico_insert on public.perfil_academico_usuario
for insert with check (auth.uid() = usuario_id);

drop policy if exists perfil_academico_update on public.perfil_academico_usuario;
create policy perfil_academico_update on public.perfil_academico_usuario
for update using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);

drop policy if exists perfil_academico_delete on public.perfil_academico_usuario;
create policy perfil_academico_delete on public.perfil_academico_usuario
for delete using (auth.uid() = usuario_id);

drop policy if exists carga_academica_select on public.carga_academica_semanal;
create policy carga_academica_select on public.carga_academica_semanal
for select using (auth.uid() = usuario_id);

drop policy if exists carga_academica_insert on public.carga_academica_semanal;
create policy carga_academica_insert on public.carga_academica_semanal
for insert with check (auth.uid() = usuario_id);

drop policy if exists carga_academica_update on public.carga_academica_semanal;
create policy carga_academica_update on public.carga_academica_semanal
for update using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);

drop policy if exists carga_academica_delete on public.carga_academica_semanal;
create policy carga_academica_delete on public.carga_academica_semanal
for delete using (auth.uid() = usuario_id);

-- -----------------------------------------------------------------------------
-- 5) Permisos explicitos para PostgREST en tablas nuevas
-- -----------------------------------------------------------------------------
grant select on table public.perfil_academico_usuario to anon;
grant select, insert, update, delete on table public.perfil_academico_usuario to authenticated;
grant all privileges on table public.perfil_academico_usuario to service_role;

grant select on table public.carga_academica_semanal to anon;
grant select, insert, update, delete on table public.carga_academica_semanal to authenticated;
grant all privileges on table public.carga_academica_semanal to service_role;

commit;
