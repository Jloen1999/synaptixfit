-- Aula habitual de la asignatura (ADR 0036), opcional y editable. La tarjeta dice «Próxima clase: lun 10:00 · Aula 2.3»
-- con el aula de esa clase (la del horario importado) o, si la clase no la trae, con esta.
ALTER TABLE asignaturas ADD COLUMN aula VARCHAR(100);
