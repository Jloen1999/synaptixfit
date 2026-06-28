-- Migración 0025: Corregir restricciones UNIQUE para upsert de ICS
-- Las partial indexes (WHERE ics_uid IS NOT NULL) no son compatibles con ON CONFLICT (col1,col2).
-- Se reemplazan por UNIQUE CONSTRAINTS reales.

DROP INDEX IF EXISTS idx_entregas_ics_uid;
DROP INDEX IF EXISTS idx_horarios_ics_uid;

ALTER TABLE entregas_examenes
  ADD CONSTRAINT uq_entregas_examenes_usuario_ics_uid
  UNIQUE (usuario_id, ics_uid);

ALTER TABLE horarios_academicos
  ADD CONSTRAINT uq_horarios_academicos_usuario_ics_uid
  UNIQUE (usuario_id, ics_uid);
