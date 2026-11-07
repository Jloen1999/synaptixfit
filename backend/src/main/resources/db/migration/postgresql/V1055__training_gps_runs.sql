-- Carreras con GPS y entrenos de carrera por pasos (ADR 0037).
-- Una carrera es una actividad: su bloque del calendario (completado) y su fila de actividades_apuntadas, con el
-- origen GPS; la ruta y las cifras calculadas en el servidor van en carreras_gps. Todo se borra con su bloque.

ALTER TABLE actividades_apuntadas ADD COLUMN origen varchar(10) NOT NULL DEFAULT 'MANUAL';
ALTER TABLE actividades_apuntadas ADD CONSTRAINT ck_actividades_apuntadas_origen CHECK (origen IN ('MANUAL', 'GPS'));

-- Entrenos de carrera por pasos (calentar, correr, recuperar, enfriar), con repeticiones. Los pasos van en JSON
-- porque solo se leen y se escriben enteros (nunca se consultan por dentro).
CREATE TABLE entrenos_carrera (
    id uuid PRIMARY KEY,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    nombre varchar(80) NOT NULL,
    plantilla varchar(30),
    pasos jsonb NOT NULL,
    creado_en timestamptz NOT NULL,
    actualizado_en timestamptz NOT NULL
);

CREATE INDEX idx_entrenos_carrera_usuario ON entrenos_carrera (usuario_id);

-- Ruta y cifras de una carrera grabada con el GPS. La clave del cliente hace la subida idempotente: la cola de
-- envíos del móvil puede reintentar sin crear dos carreras.
CREATE TABLE carreras_gps (
    bloque_id uuid PRIMARY KEY REFERENCES horarios_academicos (id) ON DELETE CASCADE,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    clave_cliente uuid NOT NULL,
    clase varchar(10) NOT NULL,
    iniciada_en timestamptz NOT NULL,
    terminada_en timestamptz NOT NULL,
    segundos_movimiento integer NOT NULL,
    distancia_metros integer NOT NULL,
    desnivel_metros integer NOT NULL,
    kcal integer,
    esfuerzo smallint NOT NULL,
    tramos jsonb NOT NULL,
    ruta jsonb NOT NULL,
    entreno_carrera_id uuid REFERENCES entrenos_carrera (id) ON DELETE SET NULL,
    creado_en timestamptz NOT NULL,
    CONSTRAINT uq_carreras_gps_clave UNIQUE (usuario_id, clave_cliente),
    CONSTRAINT ck_carreras_gps_clase CHECK (clase IN ('RUN', 'WALK', 'BIKE')),
    CONSTRAINT ck_carreras_gps_esfuerzo CHECK (esfuerzo BETWEEN 1 AND 10)
);

CREATE INDEX idx_carreras_gps_usuario_inicio ON carreras_gps (usuario_id, iniciada_en);

-- Evento del calendario (tipo Entreno) creado con «Poner en el calendario» desde un entreno de carrera.
CREATE TABLE eventos_entreno_carrera (
    bloque_id uuid PRIMARY KEY REFERENCES horarios_academicos (id) ON DELETE CASCADE,
    entreno_carrera_id uuid NOT NULL REFERENCES entrenos_carrera (id) ON DELETE CASCADE,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE
);

CREATE INDEX idx_eventos_entreno_carrera_usuario ON eventos_entreno_carrera (usuario_id);
