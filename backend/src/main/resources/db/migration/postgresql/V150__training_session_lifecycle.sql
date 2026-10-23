-- Entrenamiento: ciclo de vida de las sesiones y experiencia otorgada (anti-farmeo).
--
-- 1. Una sesión en curso tiene completada_en NULL (antes se insertaba con valores ficticios:
--    1 minuto, RPE 5 y la hora de inicio como hora de finalización). Las consultas de otros módulos
--    que cuentan sesiones por completada_en ya excluyen las que están en curso.
-- 2. xp_otorgado guarda la experiencia exacta concedida al finalizar, para restar esa misma
--    cantidad si el usuario desmarca la sesión.

ALTER TABLE sesiones_registradas ALTER COLUMN completada_en DROP NOT NULL;
ALTER TABLE sesiones_registradas ALTER COLUMN duracion_minutos SET DEFAULT 0;

ALTER TABLE sesiones_registradas DROP CONSTRAINT ck_sesiones_duracion;
ALTER TABLE sesiones_registradas
    ADD CONSTRAINT ck_sesiones_duracion
        CHECK (duracion_minutos >= 0 AND (completada_en IS NULL OR duracion_minutos > 0));

ALTER TABLE sesiones_registradas
    ADD COLUMN xp_otorgado integer DEFAULT 0 NOT NULL
        CONSTRAINT ck_sesiones_xp_otorgado CHECK (xp_otorgado >= 0);

CREATE INDEX idx_sesiones_en_curso_dia ON sesiones_registradas USING btree (usuario_id, dia_id)
    WHERE (completada_en IS NULL);
