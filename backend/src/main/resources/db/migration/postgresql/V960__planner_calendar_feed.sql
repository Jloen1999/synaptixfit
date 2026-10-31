-- Suscripción al calendario: enlace privado .ics que Google Calendar, Apple Calendar u Outlook consultan solos.
-- Solo se guarda la huella SHA-256 del token (64 hex): el enlace no se puede reconstruir desde la BD y se revoca
-- borrando la fila. Un enlace por usuario; crear otro sustituye al anterior.
CREATE TABLE suscripciones_calendario (
    usuario_id uuid PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    token_hash varchar(64) NOT NULL UNIQUE,
    creado_en timestamp with time zone NOT NULL
);
