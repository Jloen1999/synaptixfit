-- Plantillas de rutina con lugar, nivel y días de carrera (ADR 0043). Los datos nuevos llegan en V1061.

-- Dónde se entrena: gimnasio, casa o fuera (parque, pista). «en_casa» se conserva para las apps anteriores
-- y coincide siempre con lugar = 'HOME'.
ALTER TABLE plantillas_rutina
    ADD COLUMN lugar text NOT NULL DEFAULT 'GYM' CHECK (lugar IN ('GYM', 'HOME', 'OUTDOOR')),
    ADD COLUMN nivel text NOT NULL DEFAULT 'BEGINNER' CHECK (nivel IN ('BEGINNER', 'INTERMEDIATE'));

UPDATE plantillas_rutina SET lugar = 'HOME' WHERE en_casa;
-- Más volumen o cargas altas: para quien ya entrena con constancia.
UPDATE plantillas_rutina SET nivel = 'INTERMEDIATE' WHERE codigo IN ('torso_pierna_4', 'cinco_dias', 'fuerza_3');

-- Días de la semana que se sale a correr con un entreno de carrera (código de RunWorkoutTemplates). No
-- comparten día con los de fuerza: el alta los crea en Entreno › Correr, no en la rutina.
CREATE TABLE plantillas_rutina_carreras (
    plantilla_id   uuid    NOT NULL REFERENCES plantillas_rutina (id) ON DELETE CASCADE,
    dia            integer NOT NULL CHECK (dia BETWEEN 1 AND 7),
    codigo_entreno text    NOT NULL,
    PRIMARY KEY (plantilla_id, dia)
);

-- Nombre por idioma del entreno de carrera que crea una plantilla (el mismo texto que pone la app).
CREATE TABLE nombres_entreno_carrera (
    codigo text NOT NULL,
    idioma text NOT NULL,
    nombre text NOT NULL CHECK (char_length(nombre) BETWEEN 1 AND 80),
    PRIMARY KEY (codigo, idioma)
);
