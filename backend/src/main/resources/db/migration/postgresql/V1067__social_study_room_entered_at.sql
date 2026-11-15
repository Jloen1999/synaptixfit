-- «Estudiamos juntos» (ADR 0045, cierre del plan premium): cuándo entró cada persona la última vez. Con ella, salir de
-- la sala o bloquear ya no apunta Pomodoros en ese momento (un fallo al apuntar impedía salir): las rondas que
-- terminaron con la persona dentro las apunta el programador al minuto, aunque ya se haya ido. Las filas de antes
-- toman su último cambio si siguen dentro (lo mismo que se usaba hasta ahora).
ALTER TABLE salas_estudio_miembros
    ADD COLUMN entro_en timestamptz;

UPDATE salas_estudio_miembros
SET entro_en = actualizado_en
WHERE estado = 'JOINED';
