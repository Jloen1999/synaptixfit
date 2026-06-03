-- Migration: 0036_insertar_partes_cuerpo_final
-- Objetivo: Insertar 19 partes del cuerpo del dataset final

insert into public.partes_cuerpo (nombre) values
  ('Antebrazos'),
  ('Brazos'),
  ('Cadera'),
  ('Caderas'),
  ('Core'),
  ('Cuello'),
  ('Cuerpo completo'),
  ('Espalda'),
  ('Espalda alta'),
  ('Flexibilidad'),
  ('Hombros'),
  ('Manos'),
  ('Movilidad'),
  ('Pecho'),
  ('Piernas'),
  ('Pies'),
  ('Tren inferior'),
  ('Tren superior'),
  ('Zona media')
on conflict (nombre) do nothing;
