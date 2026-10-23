-- Módulo social: quién reporta un comentario (simétrico con actividades_sociales.reportado_por)
-- e índices para las consultas de moderación y del centro de notificaciones.

ALTER TABLE comentarios_feed
    ADD COLUMN reportado_por uuid REFERENCES usuarios(id) ON DELETE SET NULL;

-- Cola de moderación: solo filas reportadas.
CREATE INDEX idx_actividades_reportadas ON actividades_sociales (creado_en DESC) WHERE reportado = true;
CREATE INDEX idx_comentarios_reportados ON comentarios_feed (creado_en DESC)
    WHERE reportado = true AND eliminado = false;

-- Centro de notificaciones: listado por usuario y fecha, y contador de no leídas.
CREATE INDEX idx_notif_usuario_creado ON notificaciones (usuario_id, creado_en DESC);
CREATE INDEX idx_notif_usuario_no_leidas ON notificaciones (usuario_id, prioridad) WHERE esta_leida = false;

-- Relación entre dos usuarios en cualquier sentido (visibilidad del muro).
CREATE INDEX idx_amistades_pareja_inversa ON amistades (receptor_id, solicitante_id);
