-- Carga física de los bloques de deporte del calendario que no son una sesión de rutina
-- (p. ej. «Fútbol 90 min»): hasta ahora daban XP pero no contaban para el ACWR ni la fatiga.
-- Cada registro viene de una sesión (sesion_id) o de un bloque (bloque_id).
ALTER TABLE registros_carga_fisica ADD COLUMN bloque_id uuid;

ALTER TABLE registros_carga_fisica
    ADD CONSTRAINT registros_carga_fisica_bloque_id_fkey
    FOREIGN KEY (bloque_id) REFERENCES horarios_academicos(id) ON DELETE CASCADE;

CREATE INDEX idx_carga_fisica_bloque ON registros_carga_fisica (bloque_id);
