-- Añade metadatos de privacidad y tipo de clase a los bloques horarios.
BEGIN;

ALTER TABLE horarios_academicos
    ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS tipo_clase VARCHAR;

COMMENT ON COLUMN horarios_academicos.is_private IS
    'Si es true, el bloque solo es visible para el dueño.';
COMMENT ON COLUMN horarios_academicos.tipo_clase IS
    'Tipo de clase: ''teoria'' (teórica) o ''practica'' (práctica). Nulo si no es clase.';

COMMIT;
