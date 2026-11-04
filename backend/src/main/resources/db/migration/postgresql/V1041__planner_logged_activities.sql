-- Deporte apuntado a mano (ADR 0033): clase de deporte, minutos reales (desde 10; el bloque del calendario ocupa
-- al menos 30 terminando cuando terminó la actividad) y distancia para calcular el ritmo. Se borra con su bloque.
CREATE TABLE actividades_apuntadas (
    bloque_id uuid PRIMARY KEY REFERENCES horarios_academicos (id) ON DELETE CASCADE,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    clase varchar(10) NOT NULL,
    minutos_reales integer NOT NULL,
    distancia_metros integer,
    creado_en timestamptz NOT NULL,
    CONSTRAINT ck_actividades_apuntadas_clase CHECK (clase IN ('RUN', 'WALK', 'BIKE', 'SWIM', 'MATCH', 'OTHER')),
    CONSTRAINT ck_actividades_apuntadas_minutos CHECK (minutos_reales BETWEEN 10 AND 300),
    CONSTRAINT ck_actividades_apuntadas_distancia CHECK (distancia_metros IS NULL
        OR distancia_metros BETWEEN 100 AND 300000)
);

CREATE INDEX idx_actividades_apuntadas_usuario ON actividades_apuntadas (usuario_id);
