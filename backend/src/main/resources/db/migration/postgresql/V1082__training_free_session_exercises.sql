-- Sesión libre con ejercicios (ADR 0067). Cada sesión libre lleva su propia lista de ejercicios, elegida al empezar
-- (a mano, repitiendo una sesión o desde un día de plantilla) o sumada sobre la marcha, con sus cifras de partida.
CREATE TABLE ejercicios_sesion_libre (
    id uuid PRIMARY KEY,
    sesion_id uuid NOT NULL REFERENCES sesiones_registradas(id) ON DELETE CASCADE,
    ejercicio_id uuid NOT NULL REFERENCES ejercicios(id),
    orden integer NOT NULL,
    series integer NOT NULL CHECK (series BETWEEN 1 AND 10),
    repeticiones integer NOT NULL CHECK (repeticiones BETWEEN 1 AND 100),
    descanso_segundos integer NOT NULL CHECK (descanso_segundos BETWEEN 30 AND 300),
    peso_kg double precision,
    duracion_objetivo_segundos integer,
    distancia_metros integer,
    segundos_isometricos integer,
    rep_min integer,
    rep_max integer,
    reps_en_reserva integer,
    CONSTRAINT uq_ejercicios_sesion_libre UNIQUE (sesion_id, ejercicio_id)
);
CREATE INDEX idx_ejercicios_sesion_libre_sesion ON ejercicios_sesion_libre (sesion_id);

-- La serie de una sesión libre enlaza con su hueco de esa lista (la de rutina sigue en seleccion_id). Las series
-- libres anteriores no tienen ejercicio (ejercicio_id y hueco_libre_id nulos): se quedan como «sin ejercicio».
ALTER TABLE series_sesion ADD COLUMN hueco_libre_id uuid;
ALTER TABLE series_sesion ADD CONSTRAINT series_sesion_hueco_libre_id_fkey
    FOREIGN KEY (hueco_libre_id) REFERENCES ejercicios_sesion_libre(id) ON DELETE SET NULL;
