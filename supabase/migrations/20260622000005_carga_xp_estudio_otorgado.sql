-- Fix divergencia de esquema: la columna xp_estudio_otorgado existía en local
-- y en el esquema base, pero faltaba en remoto, provocando el error 42703
-- "column carga_academica_semanal.xp_estudio_otorgado does not exist" al
-- sincronizar la carga académica (p. ej. al completar un bloque de estudio).
-- Idempotente: no falla si ya existe.

ALTER TABLE public.carga_academica_semanal
  ADD COLUMN IF NOT EXISTS xp_estudio_otorgado boolean NOT NULL DEFAULT false;
