-- Migration: Corrige el CHECK de visibilidad en apuntes
--
-- La tabla `apuntes` se creó originalmente (migración heredada
-- 202605050012_apuntes.sql) con un CHECK en español
-- (privado / publico / amigos). La migración 20260616000004_consolidacion_fixes.sql
-- usa CREATE TABLE IF NOT EXISTS, por lo que en la BD remota —donde la tabla ya
-- existía— el constraint antiguo se mantuvo intacto.
--
-- El código de la app (crearApunte, ApuntesEditorScreen, EditorApunteScreen,
-- _VisibilidadChip) usa los valores canónicos en inglés: private / public /
-- solo_amigos. Insertar 'private' violaba el constraint heredado y producía:
--   ERROR 23514: new row for relation "apuntes" violates check constraint
--                "apuntes_visibilidad_check"
--
-- Esta migración elimina el constraint heredado, normaliza los datos existentes
-- y vuelve a crear el constraint y el DEFAULT con los valores canónicos.

-- 1. Eliminar el constraint heredado ANTES de normalizar, para que los UPDATE
--    a los nuevos valores no lo violen.
ALTER TABLE public.apuntes
    DROP CONSTRAINT IF EXISTS apuntes_visibilidad_check;

-- 2. Normalizar los datos existentes (español/legacy -> canónico).
UPDATE public.apuntes SET visibilidad = 'private'
    WHERE visibilidad = 'privado';
UPDATE public.apuntes SET visibilidad = 'public'
    WHERE visibilidad = 'publico';
UPDATE public.apuntes SET visibilidad = 'solo_amigos'
    WHERE visibilidad IN ('amigos', 'friends');

-- 2b. Defensivo: cualquier valor inesperado pasa a 'private'.
UPDATE public.apuntes SET visibilidad = 'private'
    WHERE visibilidad NOT IN ('private', 'public', 'solo_amigos');

-- 3. Restablecer el DEFAULT canónico.
ALTER TABLE public.apuntes
    ALTER COLUMN visibilidad SET DEFAULT 'private';

-- 4. Volver a crear el constraint con los valores que usa la app.
ALTER TABLE public.apuntes
    ADD CONSTRAINT apuntes_visibilidad_check
    CHECK (visibilidad IN ('private', 'public', 'solo_amigos'));
