-- Migration: 0023_actualizar_dificultad_ejercicios
-- Objetivo: Cambiar el CHECK de dificultad en ejercicios de
--           ('facil', 'medio', 'dificil') a ('principiante', 'intermedio', 'avanzado')
--           para coincidir con la nomenclatura del JSON.

alter table public.ejercicios
  drop constraint if exists ck_ejercicios_dificultad;

alter table public.ejercicios
  add constraint ck_ejercicios_dificultad
  check (dificultad in ('principiante', 'intermedio', 'avanzado'));
