-- Avisos (ADR 0035): antelación elegida por la persona y resumen de la mañana. Los valores por defecto repiten lo
-- que la app hacía antes (15 minutos antes de eventos y clases; entregas y exámenes 3 días y 1 día antes), así que
-- quien no toque nada recibe los mismos avisos. Las opciones cerradas se validan en el dominio (ReminderOptions).
ALTER TABLE opciones_avisos ADD COLUMN antelacion_eventos_min integer NOT NULL DEFAULT 15;
ALTER TABLE opciones_avisos ADD COLUMN entregas_1_dia boolean NOT NULL DEFAULT true;
ALTER TABLE opciones_avisos ADD COLUMN entregas_3_dias boolean NOT NULL DEFAULT true;
ALTER TABLE opciones_avisos ADD COLUMN entregas_7_dias boolean NOT NULL DEFAULT false;
-- EVENING_BEFORE (la tarde anterior) o MORNING_OF (la mañana del día).
ALTER TABLE opciones_avisos ADD COLUMN tareas_reto varchar(16) NOT NULL DEFAULT 'EVENING_BEFORE';
-- Hora local del resumen de la mañana; nula: apagado.
ALTER TABLE opciones_avisos ADD COLUMN hora_resumen time DEFAULT '08:00';
