-- Cada serie guarda el ejercicio que se hizo (ADR 0027). Antes solo enlazaba con el hueco de la rutina
-- (seleccion_id, ON DELETE SET NULL): al quitar o sustituir ese hueco, la serie perdía su ejercicio y el
-- historial y los récords dejaban de saber qué fue.
ALTER TABLE series_sesion ADD COLUMN ejercicio_id uuid;
ALTER TABLE series_sesion ADD CONSTRAINT series_sesion_ejercicio_id_fkey
    FOREIGN KEY (ejercicio_id) REFERENCES ejercicios(id) ON DELETE SET NULL;

-- Series ya registradas: el ejercicio de su hueco, si aún existe (SQL estándar, sin UPDATE ... FROM).
UPDATE series_sesion
SET ejercicio_id = (SELECT sel.ejercicio_id FROM seleccion_de_ejercicios sel WHERE sel.id = series_sesion.seleccion_id)
WHERE seleccion_id IS NOT NULL;

CREATE INDEX idx_series_sesion_ejercicio ON series_sesion (ejercicio_id);
