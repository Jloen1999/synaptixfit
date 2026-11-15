-- «Con amigos» asíncrono (ADR 0044): retos privados entre amigos, rachas con un amigo, «Entrenamos juntos» y
-- denuncias de personas. Solo guarda quién está en qué y cuándo: lo que suma cada uno lo recalcula el servidor con
-- los datos de siempre (repasos, Pomodoros, entrenos), y nunca datos de bienestar.

-- 1. Retos con amigos: salen de una plantilla de reto (V1062); de 7 a 14 días; la meta de cada persona y el tope
--    diario se fijan al crear.
CREATE TABLE retos_amigos (
    id               uuid PRIMARY KEY,
    creador_id       uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    plantilla_id     uuid        NOT NULL REFERENCES plantillas_reto (id),
    modo             text        NOT NULL CHECK (modo IN ('COOPERATIVE', 'COMPETITION')),
    inicio           timestamptz NOT NULL,
    fin              timestamptz NOT NULL,
    dias             integer     NOT NULL CHECK (dias BETWEEN 7 AND 14),
    objetivo_persona integer     NOT NULL CHECK (objetivo_persona BETWEEN 1 AND 10000),
    tope_diario      integer     NOT NULL CHECK (tope_diario BETWEEN 1 AND 10000),
    creado_en        timestamptz NOT NULL,
    CONSTRAINT ck_retos_amigos_fechas CHECK (fin > inicio)
);

CREATE TABLE retos_amigos_miembros (
    reto_id        uuid        NOT NULL REFERENCES retos_amigos (id) ON DELETE CASCADE,
    usuario_id     uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    estado         text        NOT NULL CHECK (estado IN ('INVITED', 'JOINED', 'DECLINED', 'LEFT')),
    actualizado_en timestamptz NOT NULL,
    PRIMARY KEY (reto_id, usuario_id)
);

CREATE INDEX idx_retos_amigos_miembros_usuario ON retos_amigos_miembros (usuario_id);

-- 2. Tablón: una reacción fija por persona y entrada (quién sumó y qué día).
CREATE TABLE reacciones_reto_amigos (
    reto_id         uuid        NOT NULL REFERENCES retos_amigos (id) ON DELETE CASCADE,
    destinatario_id uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    dia             date        NOT NULL,
    autor_id        uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    reaccion        text        NOT NULL CHECK (reaccion IN ('CLAP', 'FIRE', 'MUSCLE', 'HEART')),
    creado_en       timestamptz NOT NULL,
    PRIMARY KEY (reto_id, destinatario_id, dia, autor_id)
);

-- 3. Rachas con un amigo: una por pareja. usuario_menor/usuario_mayor guardan la pareja en un orden fijo (lo decide
--    el dominio) para que el índice único valga aunque los dos se la propongan a la vez.
CREATE TABLE rachas_amigo (
    id             uuid PRIMARY KEY,
    solicitante_id uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    receptor_id    uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    usuario_menor  uuid        NOT NULL,
    usuario_mayor  uuid        NOT NULL,
    estado         text        NOT NULL CHECK (estado IN ('PENDING', 'ACTIVE')),
    desde          date,
    ultimo_aviso   date,
    creado_en      timestamptz NOT NULL,
    actualizado_en timestamptz NOT NULL,
    CONSTRAINT ck_rachas_amigo_pareja CHECK (solicitante_id <> receptor_id),
    CONSTRAINT ck_rachas_amigo_desde CHECK (estado = 'PENDING' OR desde IS NOT NULL)
);

CREATE UNIQUE INDEX ux_rachas_amigo_pareja ON rachas_amigo (usuario_menor, usuario_mayor);
CREATE INDEX idx_rachas_amigo_solicitante ON rachas_amigo (solicitante_id);
CREATE INDEX idx_rachas_amigo_receptor ON rachas_amigo (receptor_id);

-- 4. «Entrenamos juntos»: un día de la rutina de quien invita, para la fecha en que se crea. Cada persona entrena con
--    su propia sesión (sesion_id); al borrar la sesión el vínculo se queda vacío.
CREATE TABLE entrenos_juntos (
    id            uuid PRIMARY KEY,
    anfitrion_id  uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    rutina_id     uuid        NOT NULL REFERENCES rutinas (id) ON DELETE CASCADE,
    dia_rutina_id uuid        NOT NULL REFERENCES dias_rutina (id) ON DELETE CASCADE,
    fecha         date        NOT NULL,
    creado_en     timestamptz NOT NULL
);

CREATE TABLE entrenos_juntos_miembros (
    entreno_id     uuid        NOT NULL REFERENCES entrenos_juntos (id) ON DELETE CASCADE,
    usuario_id     uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    estado         text        NOT NULL CHECK (estado IN ('INVITED', 'JOINED', 'DECLINED', 'LEFT')),
    sesion_id      uuid REFERENCES sesiones_registradas (id) ON DELETE SET NULL,
    actualizado_en timestamptz NOT NULL,
    PRIMARY KEY (entreno_id, usuario_id)
);

CREATE INDEX idx_entrenos_juntos_miembros_usuario ON entrenos_juntos_miembros (usuario_id);
CREATE INDEX idx_entrenos_juntos_miembros_sesion ON entrenos_juntos_miembros (sesion_id);

-- 5. Denuncias de personas desde lo compartido con amigos (sin texto libre: solo dónde pasó).
CREATE TABLE denuncias_usuario (
    id             uuid PRIMARY KEY,
    denunciante_id uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    denunciado_id  uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    contexto       text        NOT NULL CHECK (contexto IN ('FRIEND_CHALLENGE', 'FRIEND_STREAK', 'WORKOUT_TOGETHER',
                                                            'PROFILE')),
    creado_en      timestamptz NOT NULL,
    CONSTRAINT ck_denuncias_usuario_distintos CHECK (denunciante_id <> denunciado_id)
);

CREATE INDEX idx_denuncias_usuario_creado ON denuncias_usuario (creado_en);
