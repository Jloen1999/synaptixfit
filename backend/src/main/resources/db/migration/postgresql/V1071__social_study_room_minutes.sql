-- Sala de estudio con minutos a elegir (ADR 0053): concentración de 15 a 90 min y descanso de 1 a 30 min en vez de
-- solo 25 + 5 (SHORT) o 50 + 10 (LONG). Las salas que ya existen pasan a sus minutos. Los límites los comprueba el
-- dominio (StudyRoomTimes); los CHECK solo impiden datos imposibles.

ALTER TABLE salas_estudio ADD COLUMN minutos_concentracion integer;
ALTER TABLE salas_estudio ADD COLUMN minutos_descanso integer;

UPDATE salas_estudio SET minutos_concentracion = 50, minutos_descanso = 10 WHERE duracion = 'LONG';
UPDATE salas_estudio SET minutos_concentracion = 25, minutos_descanso = 5 WHERE minutos_concentracion IS NULL;

ALTER TABLE salas_estudio ALTER COLUMN minutos_concentracion SET NOT NULL;
ALTER TABLE salas_estudio ALTER COLUMN minutos_descanso SET NOT NULL;
ALTER TABLE salas_estudio ADD CONSTRAINT ck_salas_estudio_minutos
    CHECK (minutos_concentracion > 0 AND minutos_descanso > 0);

ALTER TABLE salas_estudio DROP COLUMN duracion;
