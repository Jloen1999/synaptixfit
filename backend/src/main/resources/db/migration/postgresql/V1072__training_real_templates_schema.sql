-- Plantillas reales, peso de partida y calibración (ADR 0054). Solo el esquema: los datos llegan en V1073 (rutinas y
-- perfiles de carga), V1074 (retos) y V1075 (músculos del catálogo). Las reglas viven en el dominio; los CHECK solo
-- impiden datos imposibles.

-- 1. Retirar plantillas sin borrarlas: las rutinas y los retos que salieron de ellas son copias propias y no cambian,
--    pero el catálogo deja de ofrecerlas.
ALTER TABLE plantillas_rutina ADD COLUMN activa boolean NOT NULL DEFAULT true;
ALTER TABLE plantillas_reto ADD COLUMN activa boolean NOT NULL DEFAULT true;

-- 2. Rango de repeticiones de cada ejercicio de la plantilla («8-12») y cuántas deben sobrar en cada serie (0-5). Se
--    conserva «repeticiones» (= mínimo del rango) para las apps anteriores.
ALTER TABLE plantillas_rutina_ejercicios
    ADD COLUMN rep_min integer CHECK (rep_min BETWEEN 1 AND 100),
    ADD COLUMN rep_max integer CHECK (rep_max BETWEEN 1 AND 100),
    ADD COLUMN rir_objetivo integer CHECK (rir_objetivo BETWEEN 0 AND 5),
    ADD CONSTRAINT ck_plantillas_rutina_ejercicios_rango CHECK (rep_min IS NULL OR rep_max IS NULL OR rep_min <= rep_max);

-- 3. Nombre de cada sesión de la plantilla por idioma («Piernas, pecho y espalda»).
CREATE TABLE plantillas_rutina_dias_textos (
    plantilla_id uuid    NOT NULL REFERENCES plantillas_rutina (id) ON DELETE CASCADE,
    dia          integer NOT NULL CHECK (dia BETWEEN 1 AND 7),
    idioma       text    NOT NULL,
    nombre       text    NOT NULL CHECK (char_length(nombre) BETWEEN 1 AND 120),
    PRIMARY KEY (plantilla_id, dia, idioma)
);

-- 4. Salidas a correr que cambian cada semana (plan progresivo «Empieza a correr»): semana 1..12, o 0 si se repite
--    todas las semanas (las filas que ya había).
ALTER TABLE plantillas_rutina_carreras ADD COLUMN semana integer NOT NULL DEFAULT 0 CHECK (semana BETWEEN 0 AND 12);
ALTER TABLE plantillas_rutina_carreras DROP CONSTRAINT plantillas_rutina_carreras_pkey;
ALTER TABLE plantillas_rutina_carreras ADD PRIMARY KEY (plantilla_id, semana, dia);

-- 5. El rango y las repeticiones que deben sobrar viajan a la rutina de la persona (doble progresión).
ALTER TABLE seleccion_de_ejercicios
    ADD COLUMN rep_min integer CHECK (rep_min BETWEEN 1 AND 100),
    ADD COLUMN rep_max integer CHECK (rep_max BETWEEN 1 AND 100),
    ADD COLUMN rir_objetivo integer CHECK (rir_objetivo BETWEEN 0 AND 5),
    ADD CONSTRAINT ck_seleccion_de_ejercicios_rango CHECK (rep_min IS NULL OR rep_max IS NULL OR rep_min <= rep_max);

-- 6. Cómo se carga cada ejercicio y su peso de partida (catálogo de solo lectura). Fracción del peso corporal en kg
--    totales (o por mano en mancuernas); kg por defecto si no se puede usar el peso corporal; tope del primer día;
--    tren_inferior: en barra sube de 5 en 5 kg en vez de 2,5.
CREATE TABLE cargas_iniciales_ejercicio (
    ejercicio_id           uuid         PRIMARY KEY REFERENCES ejercicios (id) ON DELETE CASCADE,
    tipo_carga             text         NOT NULL CHECK (tipo_carga IN ('BARBELL', 'DUMBBELL_PAIR', 'DUMBBELL_SINGLE',
                                                                     'KETTLEBELL', 'MACHINE', 'CABLE', 'BODYWEIGHT',
                                                                     'BAND')),
    fraccion_peso_corporal numeric(4, 3) CHECK (fraccion_peso_corporal BETWEEN 0 AND 2),
    kg_defecto             numeric(5, 2) CHECK (kg_defecto BETWEEN 0 AND 500),
    kg_tope                numeric(5, 2) CHECK (kg_tope BETWEEN 0 AND 500),
    tren_inferior          boolean      NOT NULL DEFAULT false
);

-- 7. Respuestas de calibración («¿Cuántas más podrías haber hecho?») de la primera sesión de cada ejercicio: una por
--    hueco y sesión. Son datos de la persona: entran en la exportación y se borran con la cuenta.
CREATE TABLE calibraciones_ejercicio (
    id                         uuid         PRIMARY KEY,
    usuario_id                 uuid         NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    sesion_id                  uuid         NOT NULL REFERENCES sesiones_registradas (id) ON DELETE CASCADE,
    ejercicio_seleccionado_id  uuid         NOT NULL,
    ejercicio_id               uuid         NOT NULL REFERENCES ejercicios (id),
    numero_serie               integer      NOT NULL CHECK (numero_serie BETWEEN 1 AND 50),
    respuesta                  text         NOT NULL CHECK (respuesta IN ('NONE', 'ONE_TWO', 'THREE', 'FOUR_PLUS')),
    peso_kg                    numeric(6, 2) CHECK (peso_kg BETWEEN 0 AND 500),
    paso                       text         NOT NULL CHECK (paso IN ('UP', 'KEEP', 'DOWN')),
    peso_siguiente_kg          numeric(6, 2) CHECK (peso_siguiente_kg BETWEEN 0 AND 500),
    respondida_en              timestamptz  NOT NULL,
    UNIQUE (sesion_id, ejercicio_seleccionado_id)
);

CREATE INDEX idx_calibraciones_ejercicio_usuario ON calibraciones_ejercicio (usuario_id);
