-- Estimación que aprende (ADR 0048): cada ejercicio planificado recuerda las duraciones reales de sus últimas veces
-- (como mucho tres; lo recorta el dominio, PlannedExercise.RECENT_DURATIONS) en vez de una sola. La estimación usa
-- su mediana acotada (SessionDurationEstimate), así una sesión olvidada abierta o un día raro no la estropean.

CREATE TABLE duraciones_ejercicio_rutina (
    id                        uuid        PRIMARY KEY,
    ejercicio_seleccionado_id uuid        NOT NULL REFERENCES seleccion_de_ejercicios (id) ON DELETE CASCADE,
    segundos                  integer     NOT NULL CHECK (segundos > 0),
    registrada_en             timestamptz NOT NULL
);

CREATE INDEX idx_duraciones_ejercicio_rutina_seleccion ON duraciones_ejercicio_rutina (ejercicio_seleccionado_id);

-- La duración que ya había pasa a ser la primera de cada ejercicio. Su id es el del propio ejercicio planificado:
-- es único (una por ejercicio) y evita depender de una función propia del motor para generar uuid.
INSERT INTO duraciones_ejercicio_rutina (id, ejercicio_seleccionado_id, segundos, registrada_en)
SELECT id, id, duracion_real_segundos, CURRENT_TIMESTAMP
FROM seleccion_de_ejercicios
WHERE duracion_real_segundos IS NOT NULL AND duracion_real_segundos > 0;

ALTER TABLE seleccion_de_ejercicios DROP COLUMN duracion_real_segundos;
