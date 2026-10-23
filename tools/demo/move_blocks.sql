-- move_blocks.sql — Coloca en su fecha real los bloques del calendario que el seed creó en el futuro.
--
-- La API no deja crear bloques en el pasado (BlockInPastException), así que seed_demo.py crea cada bloque
-- histórico exactamente `back` (un número entero de semanas) después de su fecha y este script lo devuelve
-- a ella. Al ser semanas enteras, el día de la semana (dia_semana) no cambia. Se ejecuta ANTES de
-- completar los bloques, para que la carga semanal y la carga cognitiva se calculen en la semana correcta.
--
-- Variables (psql \set): ids (uuid separados por comas), back (intervalo, p. ej. '84 days'),
-- created (instante que se guarda como fecha de creación) y users (emails demo separados por comas).

\set ON_ERROR_STOP 1
SET TIME ZONE 'Europe/Madrid';
BEGIN;

UPDATE horarios_academicos
SET hora_inicio = hora_inicio - :'back'::interval,
    hora_fin = hora_fin - :'back'::interval,
    creado_en = :'created'::timestamptz
WHERE id = ANY (string_to_array(:'ids', ',')::uuid[])
  AND usuario_id IN (
      SELECT id FROM usuarios
      WHERE email LIKE '%@demo.synaptixfit.test'
        AND email = ANY (string_to_array(:'users', ',')));

COMMIT;
