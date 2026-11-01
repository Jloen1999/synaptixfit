-- Retos: un bloque del calendario deja de ser un «vínculo» del reto o de la tarea (ADR 0028).
--
-- Ese vínculo no hacía nada (completar el bloque no avanzaba la tarea). Lo que funciona es asignar el
-- bloque a la tarea desde el editor de bloques (horarios_academicos.hito_id): cada bloque completado
-- avanza la tarea. Se pasa cada vínculo antiguo a ese modelo, solo entre datos del mismo usuario y sin
-- pisar una tarea o reto ya asignados al bloque, y se borra el vínculo. Las tareas ya completadas a mano
-- no reciben el bloque: con él pasarían a depender de sus bloques y podrían perder la XP ganada.
-- UPDATE ... FROM es propio de PostgreSQL (ver docs/06-ops/database_portability.md).

UPDATE horarios_academicos b
SET hito_id = h.id,
    reto_id = h.reto_id
FROM hitos_de_reto h
JOIN retos r ON r.id = h.reto_id
WHERE h.entidad_vinculada_tipo = 'bloque'
  AND h.entidad_vinculada_id = b.id
  AND r.usuario_id = b.usuario_id
  AND h.esta_completado = false
  AND b.hito_id IS NULL
  AND (b.reto_id IS NULL OR b.reto_id = h.reto_id);

UPDATE hitos_de_reto
SET entidad_vinculada_tipo = NULL,
    entidad_vinculada_id = NULL
WHERE entidad_vinculada_tipo = 'bloque';

UPDATE horarios_academicos b
SET reto_id = r.id
FROM retos r
WHERE r.entidad_vinculada_tipo = 'bloque'
  AND r.entidad_vinculada_id = b.id
  AND r.usuario_id = b.usuario_id
  AND b.reto_id IS NULL;

UPDATE retos
SET entidad_vinculada_tipo = NULL,
    entidad_vinculada_id = NULL
WHERE entidad_vinculada_tipo = 'bloque';
