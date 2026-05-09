-- Migration: añade docente y archivado a la tabla asignaturas
-- RF-ACA-06: docente opcional, archivado (soft delete sin perder historial)
-- RB-15: Archivar una asignatura no elimina su historial académico

alter table public.asignaturas
  add column if not exists docente text,
  add column if not exists archivado boolean not null default false;

-- Índice para filtrar asignaturas activas
create index if not exists idx_asignaturas_archivado on public.asignaturas (archivado);
