-- Migration: 0025_insertar_partes_cuerpo
-- Objetivo: Insertar catalogo de partes del cuerpo desde partes_cuerpo.json

insert into public.partes_cuerpo (nombre)
values
  ('abdomen'),
  ('antebrazos'),
  ('brazos (parte superior)'),
  ('cardio'),
  ('cintura'),
  ('core'),
  ('cuello'),
  ('espalda'),
  ('glúteos'),
  ('hombros'),
  ('pecho'),
  ('piernas (parte inferior)'),
  ('piernas (parte superior)')
on conflict (nombre) do nothing;

