-- WOD (ADR 0069): el entreno del día por formato (por tiempo, AMRAP, EMOM o Tabata) y las marcas de cada persona.
-- Los movimientos van en JSON porque solo se leen y se escriben enteros. La `firma` resume lo que se hace (formato,
-- límite, rondas y movimientos): dos WOD con la misma firma son «el mismo» para la mejor marca.
CREATE TABLE wods (
    id uuid PRIMARY KEY,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    fecha date NOT NULL,
    titulo varchar(80),
    fuerza varchar(300),
    formato varchar(10) NOT NULL,
    limite_segundos integer,
    rondas integer,
    movimientos jsonb NOT NULL,
    plantilla varchar(30),
    firma text NOT NULL,
    creado_en timestamptz NOT NULL,
    actualizado_en timestamptz NOT NULL,
    CONSTRAINT ck_wods_formato CHECK (formato IN ('FOR_TIME', 'AMRAP', 'EMOM', 'TABATA'))
);

CREATE INDEX idx_wods_usuario_fecha ON wods (usuario_id, fecha);

-- Una marca: cómo quedó un WOD (tiempo, rondas y repeticiones, repeticiones o carga) y en qué división. `bloque_id`
-- es su actividad apuntada (deporte WOD); si se borra el evento, la marca se queda.
CREATE TABLE resultados_wod (
    id uuid PRIMARY KEY,
    wod_id uuid NOT NULL REFERENCES wods (id) ON DELETE CASCADE,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    division varchar(10) NOT NULL,
    tipo_marca varchar(12) NOT NULL,
    valor integer NOT NULL,
    reps_extra integer,
    tope boolean NOT NULL DEFAULT false,
    segundos integer NOT NULL,
    bloque_id uuid REFERENCES horarios_academicos (id) ON DELETE SET NULL,
    hecho_en timestamptz NOT NULL,
    CONSTRAINT ck_resultados_wod_division CHECK (division IN ('RX', 'SCALED')),
    CONSTRAINT ck_resultados_wod_tipo CHECK (tipo_marca IN ('TIME', 'ROUNDS_REPS', 'REPS', 'LOAD'))
);

CREATE INDEX idx_resultados_wod_usuario ON resultados_wod (usuario_id, hecho_en);
CREATE INDEX idx_resultados_wod_wod ON resultados_wod (wod_id);

-- La actividad de una marca lleva el deporte WOD (catálogo `Sport`).
ALTER TABLE actividades_apuntadas DROP CONSTRAINT ck_actividades_apuntadas_deporte;
ALTER TABLE actividades_apuntadas ADD CONSTRAINT ck_actividades_apuntadas_deporte CHECK (deporte IN ('RUN', 'WALK',
    'BIKE', 'SWIM', 'FOOTBALL', 'PADEL', 'BASKETBALL', 'VOLLEYBALL', 'TENNIS', 'WOD', 'OTHER'));
