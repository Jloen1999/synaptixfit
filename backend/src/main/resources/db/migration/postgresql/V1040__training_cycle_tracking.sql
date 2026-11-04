-- Seguimiento del ciclo, opcional (ADR 0033). Apagado por defecto: solo existe la fila de quien lo activa, con
-- el momento del consentimiento. Son datos de salud: solo los lee su dueño, se borran con un toque y se borran
-- en cascada al eliminar la cuenta.
CREATE TABLE seguimiento_ciclo (
    usuario_id uuid PRIMARY KEY REFERENCES usuarios (id) ON DELETE CASCADE,
    activo boolean NOT NULL DEFAULT false,
    consentimiento_en timestamptz,
    actualizado_en timestamptz NOT NULL
);

-- Un día apuntado: si hay regla, la energía (LOW, NORMAL, HIGH) y las molestias separadas por comas.
CREATE TABLE dias_ciclo (
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    fecha date NOT NULL,
    regla boolean NOT NULL DEFAULT false,
    energia varchar(10),
    molestias varchar(200),
    nota varchar(300),
    actualizado_en timestamptz NOT NULL,
    PRIMARY KEY (usuario_id, fecha),
    CONSTRAINT ck_dias_ciclo_energia CHECK (energia IS NULL OR energia IN ('LOW', 'NORMAL', 'HIGH'))
);
