-- Pausas de la sesión y tiempo real de cada serie (ADR 0030). Las pausas no cuentan como tiempo
-- entrenado: la carga física y las calorías usan el tiempo activo (inicio → fin menos pausas).
ALTER TABLE sesiones_registradas ADD COLUMN pausada_en timestamp with time zone;
ALTER TABLE sesiones_registradas ADD COLUMN segundos_en_pausa integer NOT NULL DEFAULT 0;
ALTER TABLE sesiones_registradas ADD CONSTRAINT sesiones_registradas_segundos_en_pausa_check
    CHECK (segundos_en_pausa >= 0);

-- Segundos que se tardó en la serie (cronómetro de la serie, sin sus pausas). Opcional: se puede
-- marcar una serie como hecha sin haber usado el cronómetro.
ALTER TABLE series_sesion ADD COLUMN segundos_activos integer;
ALTER TABLE series_sesion ADD CONSTRAINT series_sesion_segundos_activos_check
    CHECK (segundos_activos IS NULL OR (segundos_activos >= 0 AND segundos_activos <= 14400));
