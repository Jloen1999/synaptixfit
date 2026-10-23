-- Planificador.
-- 1) Bloques de repaso espaciado: vínculo con el material de estudio para saber si ya existe un
--    repaso pendiente de ese material (el oyente de ReviewScheduled es idempotente gracias a esto).
ALTER TABLE horarios_academicos
    ADD COLUMN material_estudio_id uuid;

ALTER TABLE ONLY horarios_academicos
    ADD CONSTRAINT horarios_academicos_material_estudio_id_fkey
        FOREIGN KEY (material_estudio_id) REFERENCES materiales_estudio(id) ON DELETE SET NULL;

CREATE INDEX idx_horarios_material_estudio
    ON horarios_academicos USING btree (usuario_id, material_estudio_id)
    WHERE (material_estudio_id IS NOT NULL);

-- 2) Plan semanal: experiencia concedida al guardarlo, para restarla exactamente si se borra el plan
--    (si no, borrar y volver a guardar el plan permitiría ganarla de nuevo).
ALTER TABLE planes_estudio
    ADD COLUMN xp_planificacion_puntos integer DEFAULT 0 NOT NULL;

ALTER TABLE planes_estudio
    ADD CONSTRAINT ck_planes_xp_puntos CHECK (xp_planificacion_puntos >= 0);
