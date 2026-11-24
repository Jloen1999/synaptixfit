-- «No lo sé» (ADR 0063). Un intento puede ser «No lo sé»: cuenta como fallo de la nota más baja y la pregunta
-- vuelve antes. En las sesiones de test se guardan las preguntas con «No lo sé» y las que seguían sin contestar
-- al entregar (pasan a «No lo sé», pero no cuentan como respondidas para la XP).
ALTER TABLE intentos_pregunta ADD COLUMN no_lo_se boolean NOT NULL DEFAULT false;

ALTER TABLE test_sessions ADD COLUMN no_lo_se jsonb NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE test_sessions ADD COLUMN sin_contestar jsonb NOT NULL DEFAULT '[]'::jsonb;
