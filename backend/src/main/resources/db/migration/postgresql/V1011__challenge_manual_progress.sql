-- Retos: el progreso manual de un reto sin tareas se guarda en el propio reto (ADR 0028).
--
-- Antes se calculaba sumando el historial (progreso_de_reto), así que un reto que llegó al 100 % y luego
-- se desmarcaba seguía mostrando 100 % estando activo. Ahora «Registrar progreso» fija un valor absoluto
-- («¿cuánto llevas?») y desmarcar lo pone a 0; el historial solo anota lo avanzado.
-- Relleno: la suma del historial con tope 100; si el reto no está completado y la suma llega a 100, es el
-- caso del desmarcado y empieza en 0.

ALTER TABLE retos ADD COLUMN progreso_manual double precision DEFAULT 0 NOT NULL;
ALTER TABLE retos ADD CONSTRAINT ck_retos_progreso_manual
    CHECK (progreso_manual >= 0 AND progreso_manual <= 100);

UPDATE retos
SET progreso_manual = (
        SELECT CASE
                   WHEN coalesce(sum(p.cantidad_completada), 0) >= 100 AND retos.esta_completado = false THEN 0
                   ELSE LEAST(100, coalesce(sum(p.cantidad_completada), 0))
               END
        FROM progreso_de_reto p
        WHERE p.reto_id = retos.id AND p.hito_id IS NULL)
WHERE NOT EXISTS (SELECT 1 FROM hitos_de_reto h WHERE h.reto_id = retos.id);
