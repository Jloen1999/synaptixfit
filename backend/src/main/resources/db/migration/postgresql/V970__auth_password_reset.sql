-- Enlaces para restablecer la contraseña por correo. Como refresh_tokens, solo la huella SHA-256 del token
-- (64 hex): con la BD no se pueden usar los enlaces. Caducan a los 30 minutos y sirven una vez (usado_en).
CREATE TABLE restablecimientos_contrasena (
    id uuid PRIMARY KEY,
    usuario_id uuid NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token_hash varchar(64) NOT NULL UNIQUE,
    creado_en timestamp with time zone NOT NULL,
    expira_en timestamp with time zone NOT NULL,
    usado_en timestamp with time zone
);

-- Límite de enlaces por hora y anulación de los anteriores de un usuario.
CREATE INDEX idx_restablecimientos_usuario ON restablecimientos_contrasena (usuario_id, creado_en);
