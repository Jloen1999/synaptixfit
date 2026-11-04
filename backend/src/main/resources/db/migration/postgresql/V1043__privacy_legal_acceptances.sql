-- Aceptaciones de la política de privacidad y las condiciones (ADR 0034). Una fila por versión aceptada: así
-- queda constancia de qué texto aceptó cada persona y cuándo (responsabilidad proactiva del RGPD).
CREATE TABLE aceptaciones_legales (
    id uuid PRIMARY KEY,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    version varchar(20) NOT NULL,
    aceptada_en timestamptz NOT NULL,
    CONSTRAINT uq_aceptaciones_legales_usuario_version UNIQUE (usuario_id, version)
);

CREATE INDEX idx_aceptaciones_legales_usuario ON aceptaciones_legales (usuario_id, aceptada_en DESC);
