-- set_role.sql — Cambia el rol de una cuenta demo (admin/usuario).
--
-- El primer administrador se asigna por SQL (docs/04-guides/onboarding.md, «Primer administrador»);
-- el seed lo usa para la cuenta admin demo y purge_demo.py para quitárselo antes de borrarla si fuera
-- el último administrador. Solo actúa sobre el dominio demo.
--
-- Variables (psql \set): email y role ('admin' o 'usuario', los valores de usuarios.rol).

\set ON_ERROR_STOP 1
UPDATE usuarios
SET rol = :'role', actualizado_en = now()
WHERE email = :'email'
  AND email LIKE '%@demo.synaptixfit.test'
  AND :'role' IN ('admin', 'usuario');
