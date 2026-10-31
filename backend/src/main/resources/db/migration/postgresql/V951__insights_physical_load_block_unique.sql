-- Un bloque de deporte genera como mucho un registro de carga (clave de idempotencia, igual que
-- ux_carga_fisica_sesion para las sesiones). Varios NULL no chocan: las filas de sesiones no tienen bloque.
DROP INDEX idx_carga_fisica_bloque;
CREATE UNIQUE INDEX ux_carga_fisica_bloque ON registros_carga_fisica (bloque_id);
