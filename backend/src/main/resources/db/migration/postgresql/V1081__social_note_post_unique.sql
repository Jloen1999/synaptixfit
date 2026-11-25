-- «Compartir › En el muro» (ADR 0064): un apunte se publica una sola vez por persona. Los metadatos de esas
-- publicaciones son estables ({"entityType":"note","entityId":"…"}, Post.noteMetadata), así que el índice los
-- reconoce aunque lleguen dos peticiones a la vez; la segunda cuenta como «ya publicado» (ON CONFLICT DO NOTHING).
-- Índice parcial: propio de PostgreSQL, listado en docs/06-ops/database_portability.md.
CREATE UNIQUE INDEX ux_actividades_sociales_apunte ON actividades_sociales (usuario_id, metadata)
    WHERE tipo = 'apunte';
