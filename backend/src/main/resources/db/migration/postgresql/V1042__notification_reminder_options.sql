-- Avisos opcionales del móvil (ADR 0033): racha en riesgo, registro diario y clase a punto de empezar. Sin fila,
-- todos encendidos.
CREATE TABLE opciones_avisos (
    usuario_id uuid PRIMARY KEY REFERENCES usuarios (id) ON DELETE CASCADE,
    racha boolean NOT NULL DEFAULT true,
    registro_diario boolean NOT NULL DEFAULT true,
    clases boolean NOT NULL DEFAULT true,
    actualizado_en timestamptz NOT NULL
);
