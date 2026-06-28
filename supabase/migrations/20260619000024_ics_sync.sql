ALTER TABLE asignaturas
  ADD COLUMN IF NOT EXISTS ics_url TEXT,
  ADD COLUMN IF NOT EXISTS ultima_sincronizacion TIMESTAMPTZ;

ALTER TABLE entregas_examenes
  ADD COLUMN IF NOT EXISTS ics_uid TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_entregas_ics_uid
  ON entregas_examenes(usuario_id, ics_uid) WHERE ics_uid IS NOT NULL;

ALTER TABLE horarios_academicos
  ADD COLUMN IF NOT EXISTS ics_uid TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_horarios_ics_uid
  ON horarios_academicos(usuario_id, ics_uid) WHERE ics_uid IS NOT NULL;

COMMENT ON COLUMN asignaturas.ics_url IS 'URL de suscripción al calendario .ics de Moodle/Campus Virtual';
COMMENT ON COLUMN asignaturas.ultima_sincronizacion IS 'Timestamp de la última sincronización exitosa del .ics';
COMMENT ON COLUMN entregas_examenes.ics_uid IS 'UID del evento iCalendar original para idempotencia en upsert';
COMMENT ON COLUMN horarios_academicos.ics_uid IS 'UID del evento iCalendar original para idempotencia en upsert';
