-- Migración 0023: Infraestructura para Lienzo Continuo v2
-- Agrega soporte para hitos inamovibles (exámenes/entregas) e índice de fecha

ALTER TABLE horarios_academicos
  ADD COLUMN IF NOT EXISTS es_hito_inamovible BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_horarios_fecha_rango
  ON horarios_academicos (usuario_id, hora_inicio);

COMMENT ON COLUMN horarios_academicos.es_hito_inamovible
  IS 'Bloques que no se pueden arrastrar (exámenes, entregas). Protege contra edición accidental.';
