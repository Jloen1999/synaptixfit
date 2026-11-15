-- Momento en que la semana dio la XP de planificar (ADR 0045, cierre del plan premium). Los retos «Planifica tu
-- semana» (ADR 0043) cuentan la semana cuando se ganó, no cuando se creó el plan: un plan creado antes de empezar
-- el reto que llega a los 3 eventos después sí cuenta. Las filas anteriores toman la fecha de creación (la que se
-- usaba hasta ahora), así ninguna cifra ya mostrada cambia.
ALTER TABLE planes_estudio
    ADD COLUMN xp_planificacion_en timestamp with time zone;

UPDATE planes_estudio
SET xp_planificacion_en = creado_en
WHERE xp_planificacion_otorgado = true;
