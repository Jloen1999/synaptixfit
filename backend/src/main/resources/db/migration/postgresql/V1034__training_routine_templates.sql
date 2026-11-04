-- Plantillas de rutina listas para usar (ADR 0032): catálogo de solo lectura que la persona convierte en
-- una rutina propia con un toque. Los datos llegan en V1035.
CREATE TABLE plantillas_rutina (
    id            uuid PRIMARY KEY,
    codigo        text    NOT NULL UNIQUE,
    objetivo      text    NOT NULL,
    en_casa       boolean NOT NULL DEFAULT false,
    para_examenes boolean NOT NULL DEFAULT false,
    minutos       integer NOT NULL CHECK (minutos BETWEEN 10 AND 180),
    semanas       integer NOT NULL CHECK (semanas BETWEEN 1 AND 12),
    orden         integer NOT NULL DEFAULT 0
);

CREATE TABLE plantillas_rutina_textos (
    plantilla_id uuid NOT NULL REFERENCES plantillas_rutina (id) ON DELETE CASCADE,
    idioma       text NOT NULL,
    nombre       text NOT NULL,
    descripcion  text NOT NULL,
    PRIMARY KEY (plantilla_id, idioma)
);

CREATE TABLE plantillas_rutina_ejercicios (
    plantilla_id         uuid    NOT NULL REFERENCES plantillas_rutina (id) ON DELETE CASCADE,
    dia                  integer NOT NULL CHECK (dia BETWEEN 1 AND 7),
    orden                integer NOT NULL,
    ejercicio_id         uuid    NOT NULL REFERENCES ejercicios (id),
    series               integer NOT NULL CHECK (series BETWEEN 1 AND 10),
    repeticiones         integer NOT NULL CHECK (repeticiones BETWEEN 1 AND 100),
    descanso_segundos    integer NOT NULL CHECK (descanso_segundos BETWEEN 30 AND 600),
    segundos_isometricos integer CHECK (segundos_isometricos BETWEEN 1 AND 600),
    PRIMARY KEY (plantilla_id, dia, orden)
);
