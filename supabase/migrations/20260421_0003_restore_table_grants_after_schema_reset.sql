-- Migration: Restaurar permisos de tablas tras recrear schema public
-- Fecha: 2026-04-21
-- Contexto: Si se ejecuta DROP SCHEMA public CASCADE + CREATE SCHEMA public,
-- se pierden permisos a nivel de tabla para los roles anon/authenticated/service_role.

begin;

-- Permisos de esquema
grant usage on schema public to anon, authenticated, service_role;

-- Permisos para tablas existentes
grant select on all tables in schema public to anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant all privileges on all tables in schema public to service_role;

-- Permisos para secuencias existentes
grant usage, select on all sequences in schema public to anon;
grant usage, select on all sequences in schema public to authenticated;
grant all privileges on all sequences in schema public to service_role;

-- Permisos para futuras tablas/secuencias creadas por postgres
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
