-- Migration: 0034_preparar_dataset_final
-- Objetivo: Limpiar todas las tablas de ejercicios/rutinas/catalogos
--           y preparar el esquema para el dataset final (909 ejercicios).

begin;

-- 1) Limpiar series, sesiones, rutinas (respetando FK)
delete from series_sesion;
delete from sesiones_registradas;
delete from rutinas;
delete from dias_rutina;
delete from semanas_rutina;
delete from seleccion_de_ejercicios;

-- 2) Limpiar ejercicios y catalogos (respetando FK)
delete from ejercicios;
delete from equipamientos;
delete from musculos;
delete from partes_cuerpo;

-- 3) Cambios de esquema para dataset final
-- 3a) Quitar restricciones de nombre incompatibles con el dataset final
alter table public.ejercicios drop constraint if exists ejercicios_nombre_unique;
alter table public.ejercicios drop constraint if exists ck_ejercicios_nombre_len;

-- 3b) Quitar CHECK de finalidad (el dataset tiene 125+ valores distintos)
alter table public.ejercicios drop constraint if exists ck_ejercicios_finalidad;

-- 3c) Agregar columna url_preview para imagenes .webp de preview
alter table public.ejercicios add column if not exists url_preview text;

commit;
