-- «Estudiamos juntos» (ADR 0045): salas de 2 a 5 amigos con un temporizador común. Solo se guarda quién está, la hora
-- de inicio y cuántas rondas se han contado ya; la fase y la cuenta atrás las calcula el servidor desde la hora de
-- inicio. Cada ronda terminada se apunta como un Pomodoro normal en sesiones_focus, no aquí.

-- 1. La sala. inicio nulo = esperando a que alguien de dentro la empiece. rondas_contadas solo crece (comparar y
--    cambiar desde el servidor) para que dos peticiones a la vez no apunten dos veces la misma ronda.
CREATE TABLE salas_estudio (
    id              uuid PRIMARY KEY,
    creador_id      uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    duracion        text        NOT NULL CHECK (duracion IN ('SHORT', 'LONG')),
    rondas          integer     NOT NULL CHECK (rondas BETWEEN 1 AND 4),
    inicio          timestamptz,
    rondas_contadas integer     NOT NULL DEFAULT 0,
    creado_en       timestamptz NOT NULL,
    CONSTRAINT ck_salas_estudio_contadas CHECK (rondas_contadas BETWEEN 0 AND rondas)
);

CREATE INDEX idx_salas_estudio_creado ON salas_estudio (creado_en);

-- 2. Personas de la sala. La asignatura es la de cada uno (solo la ve esa persona) y la reacción es la última que
--    puso (fija, sin texto).
CREATE TABLE salas_estudio_miembros (
    sala_id        uuid        NOT NULL REFERENCES salas_estudio (id) ON DELETE CASCADE,
    usuario_id     uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    estado         text        NOT NULL CHECK (estado IN ('INVITED', 'JOINED', 'DECLINED', 'LEFT')),
    asignatura_id  uuid REFERENCES asignaturas (id) ON DELETE SET NULL,
    reaccion       text CHECK (reaccion IN ('CLAP', 'FIRE', 'MUSCLE', 'COFFEE')),
    reaccion_en    timestamptz,
    actualizado_en timestamptz NOT NULL,
    PRIMARY KEY (sala_id, usuario_id),
    CONSTRAINT ck_salas_estudio_miembros_reaccion CHECK ((reaccion IS NULL) = (reaccion_en IS NULL))
);

CREATE INDEX idx_salas_estudio_miembros_usuario ON salas_estudio_miembros (usuario_id);

-- 3. Denunciar a una persona también desde la sala.
ALTER TABLE denuncias_usuario DROP CONSTRAINT denuncias_usuario_contexto_check;
ALTER TABLE denuncias_usuario ADD CONSTRAINT denuncias_usuario_contexto_check
    CHECK (contexto IN ('FRIEND_CHALLENGE', 'FRIEND_STREAK', 'WORKOUT_TOGETHER', 'STUDY_ROOM', 'PROFILE'));
