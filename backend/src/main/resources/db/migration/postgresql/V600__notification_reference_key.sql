-- Clave de referencia estable de los avisos automáticos (AutomaticNotificationService):
--   challenge:<id del reto>, badge:<id de la insignia>, level:<nivel>, fatigue:<motivo>:<día>.
-- Antes se evitaban duplicados comparando tipo + título + descripción, así que un segundo reto con el
-- mismo título que otro ya completado nunca se avisaba. La regla vive en la aplicación; la base de
-- datos solo guarda la clave (ADR 0012). Las notificaciones sociales y manuales la dejan a NULL.
ALTER TABLE notificaciones ADD COLUMN clave_referencia VARCHAR(120);

CREATE INDEX idx_notif_usuario_clave ON notificaciones (usuario_id, clave_referencia);

-- Avisos ya enviados que llevan su referencia en los datos: así recompletar un reto antiguo o volver
-- a alcanzar un nivel no repite el aviso. Las insignias antiguas no guardaban su id y quedan sin clave.
UPDATE notificaciones
   SET clave_referencia = 'challenge:' || substring(url_accion FROM 13)
 WHERE tipo = 'milestone' AND titulo = '¡Reto completado!' AND url_accion LIKE '/challenges/%';

UPDATE notificaciones
   SET clave_referencia = 'level:' || substring(descripcion FROM 15)
 WHERE tipo = 'milestone' AND titulo = '¡Has subido de nivel!' AND descripcion LIKE 'Ya eres nivel %';
