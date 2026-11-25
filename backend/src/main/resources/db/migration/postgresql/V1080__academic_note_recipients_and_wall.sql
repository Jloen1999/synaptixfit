-- «Compartir» un apunte (ADR 0064).
-- «Con un amigo»: a quién se ha pasado cada apunte. Esa persona puede leerlo aunque sea privado mientras sigan siendo
-- amigos (la regla está en NoteAccess, no aquí). Se borra con el apunte o con cualquiera de las dos cuentas.
CREATE TABLE apuntes_destinatarios (
    apunte_id uuid NOT NULL REFERENCES apuntes (id) ON DELETE CASCADE,
    destinatario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    creado_en timestamp with time zone NOT NULL,
    PRIMARY KEY (apunte_id, destinatario_id)
);

CREATE INDEX idx_apuntes_destinatarios_destinatario ON apuntes_destinatarios (destinatario_id);

-- «En el muro»: una publicación nueva de tipo «apunte» (la publica el servidor con el enlace al apunte).
ALTER TABLE actividades_sociales DROP CONSTRAINT ck_actividad_tipo;
ALTER TABLE actividades_sociales ADD CONSTRAINT ck_actividad_tipo CHECK (tipo IN ('session_completed',
    'challenge_completed', 'milestone_reached', 'badge_unlocked', 'rutina', 'reto', 'apunte'));
