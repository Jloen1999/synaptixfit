-- Objetivos por serie y series de tiempo/distancia (ADR 0027).
-- seleccion_de_ejercicios: repeticiones y segundos de aguante por serie, como ya existía pesos_kg. Nulo = todas
-- las series usan el valor común (repeticiones / tiempo_isometrico_segundos), así las rutinas existentes no cambian.
ALTER TABLE seleccion_de_ejercicios ADD COLUMN repeticiones_por_serie jsonb;
ALTER TABLE seleccion_de_ejercicios ADD COLUMN segundos_isometricos_por_serie jsonb;

-- series_sesion: lo apuntado en ejercicios de tiempo (plancha, cardio) o distancia (correr, remo).
ALTER TABLE series_sesion ADD COLUMN duracion_segundos integer;
ALTER TABLE series_sesion ADD COLUMN distancia_metros integer;
ALTER TABLE series_sesion ADD CONSTRAINT ck_series_sesion_duracion
    CHECK (duracion_segundos IS NULL OR (duracion_segundos >= 0 AND duracion_segundos <= 14400));
ALTER TABLE series_sesion ADD CONSTRAINT ck_series_sesion_distancia
    CHECK (distancia_metros IS NULL OR (distancia_metros >= 0 AND distancia_metros <= 100000));
