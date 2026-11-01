-- Entrenamiento: días saltados y fecha en que se cerró cada día.
--
-- 1. Nuevo estado 'saltado' en dias_rutina: un día saltado (a mano o al completar uno posterior) ya no
--    se propone como próximo y cuenta para cerrar la semana. La regla vive en el dominio (Routine).
-- 2. cerrado_en guarda el día en que se completó o se saltó. Es el ritmo real de la rutina: el próximo
--    día se propone a partir de ahí (RoutineSchedule). Para los días ya completados se rellena con el
--    día de su última sesión terminada, en la zona por defecto de la app (Europe/Madrid).

ALTER TABLE dias_rutina DROP CONSTRAINT dias_rutina_estado_check;
ALTER TABLE dias_rutina
    ADD CONSTRAINT dias_rutina_estado_check
        CHECK (estado IN ('pendiente', 'en_progreso', 'completado', 'saltado'));

ALTER TABLE dias_rutina ADD COLUMN cerrado_en date;

UPDATE dias_rutina d
SET cerrado_en = (SELECT max(CAST((s.completada_en AT TIME ZONE 'Europe/Madrid') AS date))
                  FROM sesiones_registradas s
                  WHERE s.dia_id = d.id AND s.completada_en IS NOT NULL)
WHERE d.estado = 'completado';
