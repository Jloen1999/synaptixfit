-- Resumen semanal por correo (ADR 0022). Una fila por usuario suscrito; darse de baja la borra.
-- Doble confirmación: estado 'pendiente' hasta abrir el enlace del correo (solo se guarda su huella).
-- El token de baja va en cada correo y solo sirve para darse de baja: se guarda tal cual.
CREATE TABLE suscripciones_resumen_semanal (
    usuario_id uuid PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    estado varchar(16) NOT NULL,
    idioma varchar(5) NOT NULL,
    token_confirmacion_hash varchar(64) UNIQUE,
    token_baja varchar(64) NOT NULL UNIQUE,
    ultima_semana_enviada date,
    actualizado_en timestamp with time zone NOT NULL
);
