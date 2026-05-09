-- SynaptixFit - Initial schema for Supabase
-- Generated from docs/04-data-model.md and normalized for PostgreSQL/Supabase

begin;

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- Shared helpers
-- -----------------------------------------------------------------------------
create or replace function public.fn_set_actualizado_en()
returns trigger
language plpgsql
as $$
begin
  new.actualizado_en = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 1) usuarios
-- -----------------------------------------------------------------------------
create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  nombre_completo text not null,
  url_avatar text,
  nivel int not null default 1,
  xp_total int not null default 0,
  racha_actual int not null default 0,
  nivel_privacidad text not null default 'privado',
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  eliminado_en timestamptz,
  constraint ck_usuarios_email_len check (char_length(email) >= 5),
  constraint ck_usuarios_nombre_len check (char_length(nombre_completo) >= 2),
  constraint ck_usuarios_nivel check (nivel >= 1),
  constraint ck_usuarios_xp_total check (xp_total >= 0),
  constraint ck_usuarios_racha_actual check (racha_actual >= 0),
  constraint ck_usuarios_privacidad check (nivel_privacidad in ('publico', 'privado', 'amigos'))
);

create index if not exists idx_usuarios_creado_en on public.usuarios (creado_en desc);
create index if not exists idx_usuarios_privacidad on public.usuarios (nivel_privacidad);

create trigger trg_usuarios_actualizado_en
before update on public.usuarios
for each row
execute function public.fn_set_actualizado_en();

-- Auto-create profile row from auth.users
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.usuarios (id, email, nombre_completo, url_avatar)
  values (
    new.id,
    coalesce(new.email, new.id::text || '@local.invalid'),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, ''), '@', 1), 'usuario'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
    set email = excluded.email,
        nombre_completo = coalesce(excluded.nombre_completo, public.usuarios.nombre_completo),
        url_avatar = coalesce(excluded.url_avatar, public.usuarios.url_avatar),
        actualizado_en = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

-- -----------------------------------------------------------------------------
-- 2a) Tablas de catálogo (datos maestros, acceso público de lectura)
-- -----------------------------------------------------------------------------
create table if not exists public.partes_cuerpo (
  id serial primary key,
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

create table if not exists public.musculos (
  id serial primary key,
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

create table if not exists public.equipamientos (
  id serial primary key,
  nombre text not null unique,
  creado_en timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 2b) ejercicios (modelo normalizado v2)
-- -----------------------------------------------------------------------------
create table if not exists public.ejercicios (
  id uuid primary key default gen_random_uuid(),
  exercise_db_id text unique,
  nombre text not null,
  url_gif text,
  instrucciones text[] not null default '{}',
  dificultad text not null default 'medio',
  descripcion text,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_ejercicios_nombre_len check (char_length(nombre) >= 2),
  constraint ck_ejercicios_dificultad check (dificultad in ('facil', 'medio', 'dificil'))
);

create index if not exists idx_ejercicios_exercise_db_id on public.ejercicios (exercise_db_id);
create index if not exists idx_ejercicios_dificultad on public.ejercicios (dificultad);
create index if not exists idx_ejercicios_fts on public.ejercicios using gin (
  to_tsvector('spanish', coalesce(nombre, '') || ' ' || coalesce(descripcion, ''))
);

create trigger trg_ejercicios_actualizado_en
before update on public.ejercicios
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 2c) Tablas de relación N:M (ejercicios ↔ catálogos)
-- -----------------------------------------------------------------------------

-- Ejercicio ↔ Músculo objetivo
create table if not exists public.ejercicio_musculo_objetivo (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  musculo_id int not null references public.musculos(id) on delete cascade,
  primary key (ejercicio_id, musculo_id)
);

-- Ejercicio ↔ Músculo secundario
create table if not exists public.ejercicio_musculo_secundario (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  musculo_id int not null references public.musculos(id) on delete cascade,
  primary key (ejercicio_id, musculo_id)
);

-- Ejercicio ↔ Parte del cuerpo
create table if not exists public.ejercicio_parte_cuerpo (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  parte_cuerpo_id int not null references public.partes_cuerpo(id) on delete cascade,
  primary key (ejercicio_id, parte_cuerpo_id)
);

-- Ejercicio ↔ Equipamiento
create table if not exists public.ejercicio_equipamiento (
  ejercicio_id uuid not null references public.ejercicios(id) on delete cascade,
  equipamiento_id int not null references public.equipamientos(id) on delete cascade,
  primary key (ejercicio_id, equipamiento_id)
);

-- Índices para JOINs rápidos
create index if not exists idx_emo_musculo on public.ejercicio_musculo_objetivo (musculo_id);
create index if not exists idx_ems_musculo on public.ejercicio_musculo_secundario (musculo_id);
create index if not exists idx_epc_parte on public.ejercicio_parte_cuerpo (parte_cuerpo_id);
create index if not exists idx_ee_equip on public.ejercicio_equipamiento (equipamiento_id);

-- -----------------------------------------------------------------------------
-- 2d) Vista denormalizada para consultas rápidas desde el frontend
-- -----------------------------------------------------------------------------
create or replace view public.v_ejercicios_completos as
select
  e.id,
  e.exercise_db_id,
  e.nombre,
  e.url_gif,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
  e.creado_en,
  e.actualizado_en,
  coalesce(
    (select array_agg(distinct pc.nombre)
     from public.ejercicio_parte_cuerpo epc
     join public.partes_cuerpo pc on pc.id = epc.parte_cuerpo_id
     where epc.ejercicio_id = e.id),
    '{}'
  ) as partes_cuerpo,
  coalesce(
    (select array_agg(distinct mt.nombre)
     from public.ejercicio_musculo_objetivo emo
     join public.musculos mt on mt.id = emo.musculo_id
     where emo.ejercicio_id = e.id),
    '{}'
  ) as musculos_objetivo,
  coalesce(
    (select array_agg(distinct ms.nombre)
     from public.ejercicio_musculo_secundario ems
     join public.musculos ms on ms.id = ems.musculo_id
     where ems.ejercicio_id = e.id),
    '{}'
  ) as musculos_secundarios,
  coalesce(
    (select array_agg(distinct eq.nombre)
     from public.ejercicio_equipamiento ee
     join public.equipamientos eq on eq.id = ee.equipamiento_id
     where ee.ejercicio_id = e.id),
    '{}'
  ) as equipamientos
from public.ejercicios e;

-- -----------------------------------------------------------------------------
-- 3) rutinas
-- -----------------------------------------------------------------------------
create table if not exists public.rutinas (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  nombre text not null,
  descripcion text,
  visibilidad text not null default 'private',
  cantidad_ejercicios int not null default 0,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  eliminado_en timestamptz,
  constraint ck_rutinas_nombre_len check (char_length(nombre) >= 3),
  constraint ck_rutinas_visibilidad check (visibilidad in ('private', 'friends', 'public')),
  constraint ck_rutinas_cantidad check (cantidad_ejercicios >= 0)
);

create index if not exists idx_rutinas_usuario_id on public.rutinas (usuario_id);
create index if not exists idx_rutinas_creado_en on public.rutinas (creado_en desc);
create index if not exists idx_rutinas_visibilidad on public.rutinas (visibilidad);

create trigger trg_rutinas_actualizado_en
before update on public.rutinas
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 4) seleccion_de_ejercicios
-- -----------------------------------------------------------------------------
create table if not exists public.seleccion_de_ejercicios (
  id uuid primary key default gen_random_uuid(),
  rutina_id uuid not null references public.rutinas(id) on delete cascade,
  ejercicio_id uuid not null references public.ejercicios(id) on delete restrict,
  series int not null default 3,
  repeticiones int not null default 10,
  segundos_descanso int not null default 90,
  indice_orden int not null,
  constraint ck_sel_series check (series between 1 and 10),
  constraint ck_sel_repeticiones check (repeticiones between 1 and 100),
  constraint ck_sel_descanso check (segundos_descanso between 30 and 300),
  unique (rutina_id, indice_orden)
);

create index if not exists idx_sel_rutina_id on public.seleccion_de_ejercicios (rutina_id);
create index if not exists idx_sel_ejercicio_id on public.seleccion_de_ejercicios (ejercicio_id);

-- -----------------------------------------------------------------------------
-- 5) sesiones_registradas
-- -----------------------------------------------------------------------------
create table if not exists public.sesiones_registradas (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  rutina_id uuid references public.rutinas(id) on delete set null,
  duracion_minutos int not null,
  calorias_quemadas double precision,
  rpe int,
  completada_en timestamptz not null,
  creado_en timestamptz not null default now(),
  constraint ck_sesiones_duracion check (duracion_minutos > 0),
  constraint ck_sesiones_rpe check (rpe is null or rpe between 1 and 10)
);

create index if not exists idx_sesiones_usuario_id on public.sesiones_registradas (usuario_id);
create index if not exists idx_sesiones_completada_en on public.sesiones_registradas (completada_en desc);
create index if not exists idx_sesiones_rutina_id on public.sesiones_registradas (rutina_id);

-- -----------------------------------------------------------------------------
-- 6) retos
-- -----------------------------------------------------------------------------
create table if not exists public.retos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  titulo text not null,
  tipo text not null,
  meta text not null,
  visibilidad text not null default 'private',
  esta_completado boolean not null default false,
  fecha_inicio timestamptz not null,
  fecha_fin timestamptz not null,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_retos_titulo_len check (char_length(titulo) between 5 and 80),
  constraint ck_retos_tipo check (tipo in ('fitness', 'academic')),
  constraint ck_retos_visibilidad check (visibilidad in ('private', 'friends', 'public')),
  constraint ck_retos_fechas check (fecha_fin > fecha_inicio)
);

create index if not exists idx_retos_usuario_id on public.retos (usuario_id);
create index if not exists idx_retos_creado_en on public.retos (creado_en desc);
create index if not exists idx_retos_completado on public.retos (esta_completado);

create trigger trg_retos_actualizado_en
before update on public.retos
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 7) hitos_de_reto
-- -----------------------------------------------------------------------------
create table if not exists public.hitos_de_reto (
  id uuid primary key default gen_random_uuid(),
  reto_id uuid not null references public.retos(id) on delete cascade,
  titulo text not null,
  porcentaje_peso double precision not null,
  indice_orden int not null,
  progreso_actual double precision not null default 0,
  esta_completado boolean not null default false,
  constraint ck_hitos_titulo_len check (char_length(titulo) between 3 and 80),
  constraint ck_hitos_peso check (porcentaje_peso > 0 and porcentaje_peso <= 100),
  constraint ck_hitos_progreso check (progreso_actual >= 0 and progreso_actual <= 100),
  unique (reto_id, indice_orden)
);

create index if not exists idx_hitos_reto_id on public.hitos_de_reto (reto_id);

create or replace function public.fn_validar_suma_pesos_hitos()
returns trigger
language plpgsql
as $$
declare
  v_reto_id uuid;
  v_suma double precision;
begin
  v_reto_id := coalesce(new.reto_id, old.reto_id);

  select coalesce(sum(porcentaje_peso), 0)
  into v_suma
  from public.hitos_de_reto
  where reto_id = v_reto_id;

  if v_suma > 100 then
    raise exception 'La suma de porcentaje_peso para reto % no puede superar 100 (actual: %)', v_reto_id, v_suma;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_validar_suma_pesos_hitos on public.hitos_de_reto;
create trigger trg_validar_suma_pesos_hitos
after insert or update or delete on public.hitos_de_reto
for each row
execute function public.fn_validar_suma_pesos_hitos();

-- -----------------------------------------------------------------------------
-- 8) progreso_de_reto
-- -----------------------------------------------------------------------------
create table if not exists public.progreso_de_reto (
  id uuid primary key default gen_random_uuid(),
  reto_id uuid not null references public.retos(id) on delete cascade,
  hito_id uuid references public.hitos_de_reto(id) on delete cascade,
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  cantidad_completada double precision not null,
  registrado_en timestamptz not null,
  creado_en timestamptz not null default now(),
  constraint ck_progreso_cantidad check (cantidad_completada >= 0)
);

create index if not exists idx_progreso_reto_id on public.progreso_de_reto (reto_id);
create index if not exists idx_progreso_hito_id on public.progreso_de_reto (hito_id);
create index if not exists idx_progreso_usuario_id on public.progreso_de_reto (usuario_id);
create index if not exists idx_progreso_registrado_en on public.progreso_de_reto (registrado_en desc);

-- -----------------------------------------------------------------------------
-- 9) notificaciones
-- -----------------------------------------------------------------------------
create table if not exists public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  titulo text not null,
  descripcion text,
  prioridad text not null,
  tipo text not null,
  url_accion text,
  etiqueta_accion text,
  esta_leida boolean not null default false,
  creado_en timestamptz not null default now(),
  leida_en timestamptz,
  constraint ck_notif_prioridad check (prioridad in ('critical', 'recommended', 'informative')),
  constraint ck_notif_tipo check (tipo in ('conflict', 'fatigue_alert', 'milestone', 'social', 'academic'))
);

create index if not exists idx_notif_usuario_id on public.notificaciones (usuario_id);
create index if not exists idx_notif_creado_en on public.notificaciones (creado_en desc);
create index if not exists idx_notif_esta_leida on public.notificaciones (esta_leida);

-- -----------------------------------------------------------------------------
-- 10) asignaturas
-- -----------------------------------------------------------------------------
create table if not exists public.asignaturas (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  nombre text not null,
  codigo text,
  descripcion text,
  dificultad_percibida int not null default 3,
  creditos int not null default 3,
  prioridad text not null default 'media',
  proxima_evaluacion timestamptz,
  creado_en timestamptz not null default now(),
  constraint ck_asignaturas_nombre_len check (char_length(nombre) >= 2),
  constraint ck_asignaturas_dificultad check (dificultad_percibida between 1 and 5),
  constraint ck_asignaturas_creditos check (creditos between 1 and 30),
  constraint ck_asignaturas_prioridad check (prioridad in ('baja', 'media', 'alta'))
);

create index if not exists idx_asignaturas_usuario_id on public.asignaturas (usuario_id);
create index if not exists idx_asignaturas_proxima_evaluacion on public.asignaturas (proxima_evaluacion);

-- -----------------------------------------------------------------------------
-- 11) horarios_academicos
-- -----------------------------------------------------------------------------
create table if not exists public.horarios_academicos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  asignatura_id uuid not null references public.asignaturas(id) on delete cascade,
  hora_inicio timestamptz not null,
  hora_fin timestamptz not null,
  ubicacion text,
  tiene_conflicto boolean not null default false,
  creado_en timestamptz not null default now(),
  constraint ck_horarios_tiempo check (hora_fin > hora_inicio),
  constraint ck_horarios_duracion check (extract(epoch from (hora_fin - hora_inicio)) >= 1800)
);

create index if not exists idx_horarios_usuario_id on public.horarios_academicos (usuario_id);
create index if not exists idx_horarios_hora_inicio on public.horarios_academicos (hora_inicio);

-- -----------------------------------------------------------------------------
-- 11.1) perfil_academico_usuario
-- Contexto académico base para ajustar planes de entrenamiento y retos.
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

create index if not exists idx_perfil_academico_usuario_id on public.perfil_academico_usuario (usuario_id);

create trigger trg_perfil_academico_actualizado_en
before update on public.perfil_academico_usuario
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 11.2) carga_academica_semanal
-- Señales semanales para personalizar la carga física y académica.
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

create index if not exists idx_carga_academica_usuario_id on public.carga_academica_semanal (usuario_id);
create index if not exists idx_carga_academica_semana on public.carga_academica_semanal (semana_inicio desc);

create trigger trg_carga_academica_actualizado_en
before update on public.carga_academica_semanal
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 12) actividades_sociales
-- -----------------------------------------------------------------------------
create table if not exists public.actividades_sociales (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  tipo text not null,
  descripcion text not null,
  url_imagen text,
  creado_en timestamptz not null default now(),
  constraint ck_actividad_tipo check (tipo in (
    'session_completed', 'challenge_completed', 'milestone_reached', 'badge_unlocked'
  ))
);

create index if not exists idx_actividades_usuario_id on public.actividades_sociales (usuario_id);
create index if not exists idx_actividades_creado_en on public.actividades_sociales (creado_en desc);

-- -----------------------------------------------------------------------------
-- 13) interacciones_sociales
-- -----------------------------------------------------------------------------

-- (definido abajo)

-- -----------------------------------------------------------------------------
-- 14) perfil_bienestar_usuario (RF-BIE-01, RF-BIE-02)
-- Almacena el perfil físico y de bienestar del estudiante para calibrar
-- recomendaciones de entrenamiento.
-- -----------------------------------------------------------------------------
create table if not exists public.perfil_bienestar_usuario (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null unique references public.usuarios(id) on delete cascade,
  edad int not null,
  sexo text not null,
  ciudad text,
  peso_kg double precision not null,
  altura_cm double precision not null,
  imc double precision not null,
  nivel_actividad text not null default 'sedentario',
  objetivo_principal text not null default 'fitness_general',
  objetivos text[] not null default '{}',
  equipamiento_disponible text[] not null default '{}',
  dias_disponibles_semana int not null default 3,
  minutos_por_sesion int not null default 45,
  onboarding_completado boolean not null default false,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_perfil_edad check (edad between 15 and 80),
  constraint ck_perfil_sexo check (sexo in ('hombre', 'mujer', 'no_binario', 'prefiero_no_decirlo')),
  constraint ck_perfil_peso check (peso_kg between 30 and 250),
  constraint ck_perfil_altura check (altura_cm between 120 and 230),
  constraint ck_perfil_imc check (imc > 0),
  constraint ck_perfil_nivel_actividad check (nivel_actividad in ('sedentario', 'ligero', 'moderado', 'alto')),
  constraint ck_perfil_objetivo check (objetivo_principal in (
    'perder_peso', 'ganar_masa', 'fitness_general', 'fuerza', 'resistencia', 'movilidad'
  )),
  constraint ck_perfil_dias check (dias_disponibles_semana between 1 and 7),
  constraint ck_perfil_minutos check (minutos_por_sesion between 10 and 180)
);

create index if not exists idx_perfil_bienestar_usuario_id on public.perfil_bienestar_usuario (usuario_id);

create trigger trg_perfil_bienestar_actualizado_en
before update on public.perfil_bienestar_usuario
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 15) historial_peso (tracking periódico de peso/IMC)
-- -----------------------------------------------------------------------------
create table if not exists public.historial_peso (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  peso_kg double precision not null,
  altura_cm double precision not null,
  imc double precision not null,
  registrado_en timestamptz not null default now(),
  constraint ck_hist_peso check (peso_kg between 30 and 250),
  constraint ck_hist_altura check (altura_cm between 120 and 230),
  constraint ck_hist_imc check (imc > 0)
);

create index if not exists idx_historial_peso_usuario_id on public.historial_peso (usuario_id);
create index if not exists idx_historial_peso_registrado_en on public.historial_peso (registrado_en desc);

-- -----------------------------------------------------------------------------
-- 16) plan_entrenamiento_semanal (RF-BIE-04, RF-BIE-05)
-- Plan semanal autogenerado con sesiones, intensidad y estado.
-- -----------------------------------------------------------------------------
create table if not exists public.plan_entrenamiento_semanal (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  semana_inicio date not null,
  sesiones_planificadas int not null default 3,
  intensidad text not null default 'moderada',
  duracion_min_por_sesion int not null default 45,
  estado text not null default 'activo',
  notas text,
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_plan_sesiones check (sesiones_planificadas between 1 and 7),
  constraint ck_plan_intensidad check (intensidad in ('baja', 'moderada', 'alta')),
  constraint ck_plan_duracion check (duracion_min_por_sesion between 10 and 180),
  constraint ck_plan_estado check (estado in ('activo', 'pausado', 'completado', 'ajustado')),
  unique (usuario_id, semana_inicio)
);

create index if not exists idx_plan_entrenamiento_usuario_id on public.plan_entrenamiento_semanal (usuario_id);
create index if not exists idx_plan_entrenamiento_semana on public.plan_entrenamiento_semanal (semana_inicio desc);

create trigger trg_plan_entrenamiento_actualizado_en
before update on public.plan_entrenamiento_semanal
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 17) preferencias_notificacion (RF-NOT-03, RF-NOT-04)
-- Configuración de notificaciones por categoría y horario.
-- -----------------------------------------------------------------------------
create table if not exists public.preferencias_notificacion (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null unique references public.usuarios(id) on delete cascade,
  categorias_activas text[] not null default '{conflict,fatigue_alert,milestone,social,academic}',
  hora_silencio_inicio time,
  hora_silencio_fin time,
  limite_diario int not null default 10,
  modo_actual text not null default 'normal',
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_pref_limite check (limite_diario between 0 and 50),
  constraint ck_pref_modo check (modo_actual in ('normal', 'examenes', 'descanso'))
);

create index if not exists idx_pref_notif_usuario_id on public.preferencias_notificacion (usuario_id);

create trigger trg_pref_notif_actualizado_en
before update on public.preferencias_notificacion
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 18) amistades (RF-AUTH-03)
-- Relación entre usuarios con estado para control de visibilidad.
-- -----------------------------------------------------------------------------
create table if not exists public.amistades (
  id uuid primary key default gen_random_uuid(),
  solicitante_id uuid not null references public.usuarios(id) on delete cascade,
  receptor_id uuid not null references public.usuarios(id) on delete cascade,
  estado text not null default 'pendiente',
  creado_en timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),
  constraint ck_amistad_estado check (estado in ('pendiente', 'aceptada', 'rechazada', 'bloqueada')),
  constraint ck_amistad_no_self check (solicitante_id <> receptor_id),
  unique (solicitante_id, receptor_id)
);

create index if not exists idx_amistades_solicitante on public.amistades (solicitante_id);
create index if not exists idx_amistades_receptor on public.amistades (receptor_id);
create index if not exists idx_amistades_estado on public.amistades (estado);

create trigger trg_amistades_actualizado_en
before update on public.amistades
for each row
execute function public.fn_set_actualizado_en();

-- -----------------------------------------------------------------------------
-- 13) interacciones_sociales (continuación)
-- -----------------------------------------------------------------------------
create table if not exists public.interacciones_sociales (
  id uuid primary key default gen_random_uuid(),
  actividad_id uuid not null references public.actividades_sociales(id) on delete cascade,
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  tipo_interaccion text not null,
  texto_comentario text,
  creado_en timestamptz not null default now(),
  constraint ck_interaccion_tipo check (tipo_interaccion in ('like', 'comment')),
  constraint ck_interaccion_comentario check (
    tipo_interaccion <> 'comment' or char_length(coalesce(texto_comentario, '')) between 1 and 200
  ),
  unique (actividad_id, usuario_id, tipo_interaccion)
);

create index if not exists idx_interacciones_actividad_id on public.interacciones_sociales (actividad_id);
create index if not exists idx_interacciones_usuario_id on public.interacciones_sociales (usuario_id);

-- -----------------------------------------------------------------------------
-- Business functions
-- -----------------------------------------------------------------------------
create or replace function public.detectar_conflictos_de_horario(
  p_usuario_id uuid,
  p_inicio_semana date
)
returns table (
  id_conflicto uuid,
  id_bloque_estudio uuid,
  id_sesion_entrenamiento uuid,
  mensaje_conflicto text
)
language plpgsql
stable
as $$
begin
  return query
  select
    gen_random_uuid(),
    h.id,
    s.id,
    'Conflicto entre horario academico y sesion registrada'
  from public.horarios_academicos h
  join public.sesiones_registradas s
    on s.usuario_id = h.usuario_id
  where h.usuario_id = p_usuario_id
    and h.hora_inicio::date >= p_inicio_semana
    and h.hora_inicio::date < (p_inicio_semana + interval '7 days')::date
    and s.completada_en::date >= p_inicio_semana
    and s.completada_en::date < (p_inicio_semana + interval '7 days')::date
    and h.hora_inicio < s.completada_en + make_interval(mins => s.duracion_minutos)
    and h.hora_fin > s.completada_en;
end;
$$;

create or replace function public.calcular_progreso_de_reto(p_reto_id uuid)
returns double precision
language plpgsql
stable
as $$
declare
  v_tiene_hitos boolean;
  v_progreso double precision;
begin
  select exists(select 1 from public.hitos_de_reto h where h.reto_id = p_reto_id)
  into v_tiene_hitos;

  if not v_tiene_hitos then
    select coalesce(sum(pr.cantidad_completada), 0)
    into v_progreso
    from public.progreso_de_reto pr
    where pr.reto_id = p_reto_id;

    return least(v_progreso, 100);
  end if;

  select coalesce(sum((h.porcentaje_peso / 100.0) * (
    least(
      coalesce((
        select sum(pr2.cantidad_completada)
        from public.progreso_de_reto pr2
        where pr2.hito_id = h.id
      ), 0),
      100
    ) / 100.0
  )), 0) * 100
  into v_progreso
  from public.hitos_de_reto h
  where h.reto_id = p_reto_id;

  return least(v_progreso, 100);
end;
$$;

create or replace function public.otorgar_xp(
  p_usuario_id uuid,
  p_cantidad_xp int
)
returns table (
  nuevo_nivel int,
  nueva_xp int,
  sube_nivel boolean
)
language plpgsql
as $$
declare
  v_nivel_actual int;
  v_xp_actual int;
  v_umbral int;
  v_total int;
begin
  if p_cantidad_xp <= 0 then
    raise exception 'p_cantidad_xp debe ser mayor a 0';
  end if;

  select u.nivel, u.xp_total
  into v_nivel_actual, v_xp_actual
  from public.usuarios u
  where u.id = p_usuario_id
  for update;

  if not found then
    raise exception 'Usuario % no existe', p_usuario_id;
  end if;

  v_umbral := 1000 * v_nivel_actual;
  v_total := v_xp_actual + p_cantidad_xp;

  if v_total >= v_umbral then
    update public.usuarios
    set nivel = nivel + 1,
        xp_total = v_total - v_umbral,
        actualizado_en = now()
    where id = p_usuario_id
    returning nivel, xp_total into nuevo_nivel, nueva_xp;

    sube_nivel := true;
  else
    update public.usuarios
    set xp_total = v_total,
        actualizado_en = now()
    where id = p_usuario_id
    returning nivel, xp_total into nuevo_nivel, nueva_xp;

    sube_nivel := false;
  end if;

  return next;
end;
$$;

-- -----------------------------------------------------------------------------
-- Row level security
-- -----------------------------------------------------------------------------
alter table public.usuarios enable row level security;
alter table public.ejercicios enable row level security;
alter table public.partes_cuerpo enable row level security;
alter table public.musculos enable row level security;
alter table public.equipamientos enable row level security;
alter table public.ejercicio_musculo_objetivo enable row level security;
alter table public.ejercicio_musculo_secundario enable row level security;
alter table public.ejercicio_parte_cuerpo enable row level security;
alter table public.ejercicio_equipamiento enable row level security;
alter table public.rutinas enable row level security;
alter table public.seleccion_de_ejercicios enable row level security;
alter table public.sesiones_registradas enable row level security;
alter table public.retos enable row level security;
alter table public.hitos_de_reto enable row level security;
alter table public.progreso_de_reto enable row level security;
alter table public.notificaciones enable row level security;
alter table public.asignaturas enable row level security;
alter table public.horarios_academicos enable row level security;
alter table public.perfil_academico_usuario enable row level security;
alter table public.carga_academica_semanal enable row level security;
alter table public.actividades_sociales enable row level security;
alter table public.interacciones_sociales enable row level security;
alter table public.perfil_bienestar_usuario enable row level security;
alter table public.historial_peso enable row level security;
alter table public.plan_entrenamiento_semanal enable row level security;

-- usuarios
 drop policy if exists usuarios_select on public.usuarios;
create policy usuarios_select on public.usuarios
for select using (auth.uid() = id or nivel_privacidad = 'publico');

drop policy if exists usuarios_insert on public.usuarios;
create policy usuarios_insert on public.usuarios
for insert with check (auth.uid() = id);

drop policy if exists usuarios_update on public.usuarios;
create policy usuarios_update on public.usuarios
for update using (auth.uid() = id);

-- ejercicios (lectura pública)
 drop policy if exists ejercicios_select on public.ejercicios;
create policy ejercicios_select on public.ejercicios
for select using (true);

-- catálogos de ejercicios (lectura pública)
drop policy if exists partes_cuerpo_select on public.partes_cuerpo;
create policy partes_cuerpo_select on public.partes_cuerpo
for select using (true);

drop policy if exists musculos_select on public.musculos;
create policy musculos_select on public.musculos
for select using (true);

drop policy if exists equipamientos_select on public.equipamientos;
create policy equipamientos_select on public.equipamientos
for select using (true);

-- tablas de relación N:M (lectura pública)
drop policy if exists emo_select on public.ejercicio_musculo_objetivo;
create policy emo_select on public.ejercicio_musculo_objetivo
for select using (true);

drop policy if exists ems_select on public.ejercicio_musculo_secundario;
create policy ems_select on public.ejercicio_musculo_secundario
for select using (true);

drop policy if exists epc_select on public.ejercicio_parte_cuerpo;
create policy epc_select on public.ejercicio_parte_cuerpo
for select using (true);

drop policy if exists ee_select on public.ejercicio_equipamiento;
create policy ee_select on public.ejercicio_equipamiento
for select using (true);

-- vista denormalizada
grant select on public.v_ejercicios_completos to anon, authenticated;

-- rutinas
 drop policy if exists rutinas_select on public.rutinas;
create policy rutinas_select on public.rutinas
for select using (auth.uid() = usuario_id or visibilidad <> 'private');

drop policy if exists rutinas_insert on public.rutinas;
create policy rutinas_insert on public.rutinas
for insert with check (auth.uid() = usuario_id);

drop policy if exists rutinas_update on public.rutinas;
create policy rutinas_update on public.rutinas
for update using (auth.uid() = usuario_id);

drop policy if exists rutinas_delete on public.rutinas;
create policy rutinas_delete on public.rutinas
for delete using (auth.uid() = usuario_id);

-- seleccion_de_ejercicios
 drop policy if exists seleccion_select on public.seleccion_de_ejercicios;
create policy seleccion_select on public.seleccion_de_ejercicios
for select using (
  exists (
    select 1
    from public.rutinas r
    where r.id = rutina_id
      and (auth.uid() = r.usuario_id or r.visibilidad <> 'private')
  )
);

drop policy if exists seleccion_insert on public.seleccion_de_ejercicios;
create policy seleccion_insert on public.seleccion_de_ejercicios
for insert with check (
  exists (
    select 1
    from public.rutinas r
    where r.id = rutina_id
      and auth.uid() = r.usuario_id
  )
);

drop policy if exists seleccion_update on public.seleccion_de_ejercicios;
create policy seleccion_update on public.seleccion_de_ejercicios
for update using (
  exists (
    select 1
    from public.rutinas r
    where r.id = rutina_id
      and auth.uid() = r.usuario_id
  )
);

drop policy if exists seleccion_delete on public.seleccion_de_ejercicios;
create policy seleccion_delete on public.seleccion_de_ejercicios
for delete using (
  exists (
    select 1
    from public.rutinas r
    where r.id = rutina_id
      and auth.uid() = r.usuario_id
  )
);

-- sesiones_registradas
 drop policy if exists sesiones_select on public.sesiones_registradas;
create policy sesiones_select on public.sesiones_registradas
for select using (
  auth.uid() = usuario_id
  or exists (
    select 1 from public.usuarios u
    where u.id = usuario_id
      and u.nivel_privacidad = 'publico'
  )
);

drop policy if exists sesiones_insert on public.sesiones_registradas;
create policy sesiones_insert on public.sesiones_registradas
for insert with check (auth.uid() = usuario_id);

drop policy if exists sesiones_update on public.sesiones_registradas;
create policy sesiones_update on public.sesiones_registradas
for update using (auth.uid() = usuario_id);

drop policy if exists sesiones_delete on public.sesiones_registradas;
create policy sesiones_delete on public.sesiones_registradas
for delete using (auth.uid() = usuario_id);

-- retos
 drop policy if exists retos_select on public.retos;
create policy retos_select on public.retos
for select using (auth.uid() = usuario_id or visibilidad <> 'private');

drop policy if exists retos_insert on public.retos;
create policy retos_insert on public.retos
for insert with check (auth.uid() = usuario_id);

drop policy if exists retos_update on public.retos;
create policy retos_update on public.retos
for update using (auth.uid() = usuario_id);

drop policy if exists retos_delete on public.retos;
create policy retos_delete on public.retos
for delete using (auth.uid() = usuario_id);

-- hitos_de_reto
 drop policy if exists hitos_select on public.hitos_de_reto;
create policy hitos_select on public.hitos_de_reto
for select using (
  exists (
    select 1
    from public.retos r
    where r.id = reto_id
      and (auth.uid() = r.usuario_id or r.visibilidad <> 'private')
  )
);

drop policy if exists hitos_insert on public.hitos_de_reto;
create policy hitos_insert on public.hitos_de_reto
for insert with check (
  exists (
    select 1
    from public.retos r
    where r.id = reto_id
      and auth.uid() = r.usuario_id
  )
);

drop policy if exists hitos_update on public.hitos_de_reto;
create policy hitos_update on public.hitos_de_reto
for update using (
  exists (
    select 1
    from public.retos r
    where r.id = reto_id
      and auth.uid() = r.usuario_id
  )
);

drop policy if exists hitos_delete on public.hitos_de_reto;
create policy hitos_delete on public.hitos_de_reto
for delete using (
  exists (
    select 1
    from public.retos r
    where r.id = reto_id
      and auth.uid() = r.usuario_id
  )
);

-- progreso_de_reto
 drop policy if exists progreso_select on public.progreso_de_reto;
create policy progreso_select on public.progreso_de_reto
for select using (
  auth.uid() = usuario_id
  or exists (
    select 1
    from public.retos r
    where r.id = reto_id
      and r.visibilidad = 'public'
  )
);

drop policy if exists progreso_insert on public.progreso_de_reto;
create policy progreso_insert on public.progreso_de_reto
for insert with check (auth.uid() = usuario_id);

drop policy if exists progreso_update on public.progreso_de_reto;
create policy progreso_update on public.progreso_de_reto
for update using (auth.uid() = usuario_id);

drop policy if exists progreso_delete on public.progreso_de_reto;
create policy progreso_delete on public.progreso_de_reto
for delete using (auth.uid() = usuario_id);

-- notificaciones
 drop policy if exists notificaciones_select on public.notificaciones;
create policy notificaciones_select on public.notificaciones
for select using (auth.uid() = usuario_id);

drop policy if exists notificaciones_insert on public.notificaciones;
create policy notificaciones_insert on public.notificaciones
for insert with check (auth.uid() = usuario_id);

drop policy if exists notificaciones_update on public.notificaciones;
create policy notificaciones_update on public.notificaciones
for update using (auth.uid() = usuario_id);

drop policy if exists notificaciones_delete on public.notificaciones;
create policy notificaciones_delete on public.notificaciones
for delete using (auth.uid() = usuario_id);

-- asignaturas
 drop policy if exists asignaturas_select on public.asignaturas;
create policy asignaturas_select on public.asignaturas
for select using (auth.uid() = usuario_id);

drop policy if exists asignaturas_insert on public.asignaturas;
create policy asignaturas_insert on public.asignaturas
for insert with check (auth.uid() = usuario_id);

drop policy if exists asignaturas_update on public.asignaturas;
create policy asignaturas_update on public.asignaturas
for update using (auth.uid() = usuario_id);

drop policy if exists asignaturas_delete on public.asignaturas;
create policy asignaturas_delete on public.asignaturas
for delete using (auth.uid() = usuario_id);

-- perfil_academico_usuario
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

-- carga_academica_semanal
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

-- horarios_academicos
 drop policy if exists horarios_select on public.horarios_academicos;
create policy horarios_select on public.horarios_academicos
for select using (auth.uid() = usuario_id);

drop policy if exists horarios_insert on public.horarios_academicos;
create policy horarios_insert on public.horarios_academicos
for insert with check (auth.uid() = usuario_id);

drop policy if exists horarios_update on public.horarios_academicos;
create policy horarios_update on public.horarios_academicos
for update using (auth.uid() = usuario_id);

drop policy if exists horarios_delete on public.horarios_academicos;
create policy horarios_delete on public.horarios_academicos
for delete using (auth.uid() = usuario_id);

-- actividades_sociales
 drop policy if exists actividades_select on public.actividades_sociales;
create policy actividades_select on public.actividades_sociales
for select using (
  auth.uid() = usuario_id
  or exists (
    select 1 from public.usuarios u
    where u.id = usuario_id
      and u.nivel_privacidad = 'publico'
  )
);

drop policy if exists actividades_insert on public.actividades_sociales;
create policy actividades_insert on public.actividades_sociales
for insert with check (auth.uid() = usuario_id);

drop policy if exists actividades_update on public.actividades_sociales;
create policy actividades_update on public.actividades_sociales
for update using (auth.uid() = usuario_id);

drop policy if exists actividades_delete on public.actividades_sociales;
create policy actividades_delete on public.actividades_sociales
for delete using (auth.uid() = usuario_id);

-- interacciones_sociales
 drop policy if exists interacciones_select on public.interacciones_sociales;
create policy interacciones_select on public.interacciones_sociales
for select using (
  exists (
    select 1
    from public.actividades_sociales a
    join public.usuarios u on u.id = a.usuario_id
    where a.id = actividad_id
      and (auth.uid() = a.usuario_id or u.nivel_privacidad = 'publico')
  )
);

drop policy if exists interacciones_insert on public.interacciones_sociales;
create policy interacciones_insert on public.interacciones_sociales
for insert with check (auth.uid() = usuario_id);

drop policy if exists interacciones_update on public.interacciones_sociales;
create policy interacciones_update on public.interacciones_sociales
for update using (auth.uid() = usuario_id);

drop policy if exists interacciones_delete on public.interacciones_sociales;
create policy interacciones_delete on public.interacciones_sociales
for delete using (auth.uid() = usuario_id);

-- perfil_bienestar_usuario
drop policy if exists perfil_bienestar_select on public.perfil_bienestar_usuario;
create policy perfil_bienestar_select on public.perfil_bienestar_usuario
for select using (auth.uid() = usuario_id);

drop policy if exists perfil_bienestar_insert on public.perfil_bienestar_usuario;
create policy perfil_bienestar_insert on public.perfil_bienestar_usuario
for insert with check (auth.uid() = usuario_id);

drop policy if exists perfil_bienestar_update on public.perfil_bienestar_usuario;
create policy perfil_bienestar_update on public.perfil_bienestar_usuario
for update using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);

-- historial_peso
drop policy if exists historial_peso_select on public.historial_peso;
create policy historial_peso_select on public.historial_peso
for select using (auth.uid() = usuario_id);

drop policy if exists historial_peso_insert on public.historial_peso;
create policy historial_peso_insert on public.historial_peso
for insert with check (auth.uid() = usuario_id);

-- plan_entrenamiento_semanal
drop policy if exists plan_entrenamiento_select on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_select on public.plan_entrenamiento_semanal
for select using (auth.uid() = usuario_id);

drop policy if exists plan_entrenamiento_insert on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_insert on public.plan_entrenamiento_semanal
for insert with check (auth.uid() = usuario_id);

drop policy if exists plan_entrenamiento_update on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_update on public.plan_entrenamiento_semanal
for update using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);

drop policy if exists plan_entrenamiento_delete on public.plan_entrenamiento_semanal;
create policy plan_entrenamiento_delete on public.plan_entrenamiento_semanal
for delete using (auth.uid() = usuario_id);

-- Habilita realtime en las tablas de ejercicios para sincronización en vivo
alter publication supabase_realtime add table ejercicios;
alter publication supabase_realtime add table partes_cuerpo;
alter publication supabase_realtime add table musculos;
alter publication supabase_realtime add table equipamientos;
alter publication supabase_realtime add table ejercicio_musculo_objetivo;
alter publication supabase_realtime add table ejercicio_musculo_secundario;
alter publication supabase_realtime add table ejercicio_parte_cuerpo;
alter publication supabase_realtime add table ejercicio_equipamiento;

-- permisos base para PostgREST (evita 42501 tras reset de schema)
grant usage on schema public to anon, authenticated, service_role;
grant select on all tables in schema public to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant all privileges on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to anon;
grant usage, select on all sequences in schema public to authenticated;
grant all privileges on all sequences in schema public to service_role;

alter default privileges for role postgres in schema public
  grant select on tables to anon;
alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to authenticated;
alter default privileges for role postgres in schema public
  grant all privileges on tables to service_role;
alter default privileges for role postgres in schema public
  grant usage, select on sequences to anon;
alter default privileges for role postgres in schema public
  grant usage, select on sequences to authenticated;
alter default privileges for role postgres in schema public
  grant all privileges on sequences to service_role;

commit;
