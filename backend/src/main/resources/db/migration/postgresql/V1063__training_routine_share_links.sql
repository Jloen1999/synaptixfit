-- Enlaces para copiar una rutina (ADR 0043). Solo se guarda la huella SHA-256 del token (como el calendario
-- suscrito, ADR 0020): con la base de datos no se puede abrir ningún enlace. Caducan y se revocan; se borran con la
-- rutina o con la cuenta (cascada).
CREATE TABLE enlaces_rutina (
    id          uuid PRIMARY KEY,
    rutina_id   uuid        NOT NULL REFERENCES rutinas (id) ON DELETE CASCADE,
    usuario_id  uuid        NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    token_hash  text        NOT NULL UNIQUE,
    creado_en   timestamptz NOT NULL,
    caduca_en   timestamptz NOT NULL,
    revocado_en timestamptz,
    CONSTRAINT ck_enlaces_rutina_caducidad CHECK (caduca_en > creado_en)
);

CREATE INDEX idx_enlaces_rutina_rutina ON enlaces_rutina (rutina_id);
