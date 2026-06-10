-- ═══════════════════════════════════════════════════════════════
-- Migraciones pendientes para SynaptixFit
-- Ejecutar EN ORDEN en Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ═══ 0009: Añade docente y archivado a asignaturas ═══
alter table public.asignaturas
  add column if not exists docente text,
  add column if not exists archivado boolean not null default false;
create index if not exists idx_asignaturas_archivado on public.asignaturas (archivado);

-- ═══ 0010: Catálogo académico ═══
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
alter table public.asignaturas
  add column if not exists catalogo_asignatura_id uuid
  references public.catalogo_asignaturas(id) on delete set null;

alter table public.catalogo_universidades enable row level security;
alter table public.catalogo_carreras enable row level security;
alter table public.catalogo_asignaturas enable row level security;
drop policy if exists catalogo_universidades_select on public.catalogo_universidades;
create policy catalogo_universidades_select on public.catalogo_universidades for select using (true);
drop policy if exists catalogo_carreras_select on public.catalogo_carreras;
create policy catalogo_carreras_select on public.catalogo_carreras for select using (true);
drop policy if exists catalogo_asignaturas_select on public.catalogo_asignaturas;
create policy catalogo_asignaturas_select on public.catalogo_asignaturas for select using (true);

-- ═══ 0011: Planes de estudio semanales ═══
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

alter table public.horarios_academicos
  add column if not exists plan_estudio_id uuid
  references public.planes_estudio(id) on delete set null;
alter table public.horarios_academicos
  add column if not exists prioridad text not null default 'media'
  check (prioridad in ('alta', 'media', 'baja'));
create index if not exists idx_horarios_plan on public.horarios_academicos (plan_estudio_id);

alter table public.planes_estudio enable row level security;
drop policy if exists planes_estudio_select on public.planes_estudio;
create policy planes_estudio_select on public.planes_estudio for select using (
  visibilidad = 'publico'
  or usuario_id = auth.uid()
  or (visibilidad = 'solo_amigos' and exists (
    select 1 from public.amistades
    where (solicitante_id = auth.uid() and receptor_id = usuario_id)
       or (receptor_id = auth.uid() and solicitante_id = usuario_id)
    limit 1
  ))
);
drop policy if exists planes_estudio_insert on public.planes_estudio;
create policy planes_estudio_insert on public.planes_estudio for insert with check (usuario_id = auth.uid());
drop policy if exists planes_estudio_update on public.planes_estudio;
create policy planes_estudio_update on public.planes_estudio for update using (usuario_id = auth.uid());
drop policy if exists planes_estudio_delete on public.planes_estudio;
create policy planes_estudio_delete on public.planes_estudio for delete using (usuario_id = auth.uid());

-- ═══ 0012: Apuntes (Markdown) ═══
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

alter table public.apuntes enable row level security;
drop policy if exists apuntes_select on public.apuntes;
create policy apuntes_select on public.apuntes for select using (
  visibilidad = 'publico'
  or usuario_id = auth.uid()
  or (visibilidad = 'solo_amigos' and exists (
    select 1 from public.amistades
    where ((solicitante_id = auth.uid() and receptor_id = usuario_id)
       or (receptor_id = auth.uid() and solicitante_id = usuario_id))
      and estado = 'aceptado'
    limit 1
  ))
);
drop policy if exists apuntes_insert on public.apuntes;
create policy apuntes_insert on public.apuntes for insert with check (usuario_id = auth.uid());
drop policy if exists apuntes_update on public.apuntes;
create policy apuntes_update on public.apuntes for update using (usuario_id = auth.uid());
drop policy if exists apuntes_delete on public.apuntes;
create policy apuntes_delete on public.apuntes for delete using (usuario_id = auth.uid());

-- ═══ 0045: Pesos por serie (jsonb) ═══
alter table if exists public.seleccion_de_ejercicios
  add column if not exists pesos_kg jsonb;

-- ═══ 0046: Historial de objetivos del usuario ═══
create table if not exists public.historial_objetivos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  objetivo text not null,
  objetivo_anterior text,
  fecha_inicio date not null default current_date,
  fecha_fin date,
  rutina_ids uuid[] default '{}',
  creado_en timestamptz not null default now()
);
alter table public.historial_objetivos enable row level security;
create policy historial_objetivos_select on public.historial_objetivos
  for select using (auth.uid() = usuario_id);
create policy historial_objetivos_insert on public.historial_objetivos
  for insert with check (auth.uid() = usuario_id);
create policy historial_objetivos_update on public.historial_objetivos
  for update using (auth.uid() = usuario_id);
create index if not exists idx_historial_objetivos_usuario
  on public.historial_objetivos(usuario_id, fecha_inicio desc);

-- ═══ 0047: Failed reps por serie ═══
alter table if exists public.series_sesion
  add column if not exists failed_reps int not null default 0 check (failed_reps >= 0);

-- ═══ 0048: Recomendaciones pendientes post-sesión ═══
create table if not exists public.recomendaciones_pendientes (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  tipo text not null check (tipo in ('progresion','degradacion','descarga','variante','academico')),
  titulo text not null,
  descripcion text,
  ejercicio_id uuid references public.ejercicios(id) on delete set null,
  rutina_id uuid references public.rutinas(id) on delete set null,
  datos jsonb default '{}',
  aplicada boolean not null default false,
  creado_en timestamptz not null default now()
);
alter table public.recomendaciones_pendientes enable row level security;
create policy recom_pend_select on public.recomendaciones_pendientes
  for select using (auth.uid() = usuario_id);
create policy recom_pend_insert on public.recomendaciones_pendientes
  for insert with check (auth.uid() = usuario_id);
create policy recom_pend_update on public.recomendaciones_pendientes
  for update using (auth.uid() = usuario_id);
create index if not exists idx_recom_pend_usuario
  on public.recomendaciones_pendientes(usuario_id, creado_en desc);

-- ═══ 0049: Función de generación de recomendaciones diarias (para pg_cron) ═══
-- Ver contenido completo en: supabase/migrations/20260606_0049_func_daily_recommendations.sql

-- Para activar pg_cron (requiere extensión en Supabase Dashboard):
-- 1. Habilitar extensión pg_cron desde Supabase Dashboard → Database → Extensions
-- 2. Ejecutar en SQL Editor:
--    SELECT cron.schedule(
--      'recomendaciones-diarias',
--      '0 2 * * *',
--      'SELECT generar_recomendaciones_diarias();'
--    );
-- 3. Verificar: SELECT * FROM cron.job;

-- ═══ 0050: Eliminar constraint obsoleta ck_perfil_objetivo ═══
-- Ver contenido completo en: supabase/migrations/20260607_0050_fix_objetivo_constraint.sql
