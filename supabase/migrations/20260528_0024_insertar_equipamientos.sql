-- Migration: 0024_insertar_equipamientos
-- Objetivo: Insertar catalogo de equipamientos desde equipamientos.json

insert into public.equipamientos (nombre)
values
  ('almohada'),
  ('banco'),
  ('banco inclinado'),
  ('banda de resistencia'),
  ('barra'),
  ('barra en t'),
  ('barra ez'),
  ('barra olímpica'),
  ('cuerda'),
  ('discos de pesas'),
  ('equipo asistido'),
  ('lastre'),
  ('mancuerna'),
  ('mancuernas'),
  ('máquina contractora'),
  ('máquina convergente'),
  ('máquina de curl'),
  ('máquina de extensión'),
  ('máquina hack'),
  ('máquina smith'),
  ('pesa rusa'),
  ('peso corporal'),
  ('polea'),
  ('prensa de piernas')
on conflict (nombre) do nothing;

