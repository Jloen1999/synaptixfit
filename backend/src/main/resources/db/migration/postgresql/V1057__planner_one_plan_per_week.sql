-- Planificador (ADR 0038): la experiencia de planificar la semana se da sola al añadir eventos, así que dos
-- peticiones a la vez podrían crear dos planes de la misma semana y darla dos veces. Un índice único lo
-- impide en la base de datos. Antes se juntan los duplicados que hubiera (de cuando se guardaba a mano):
-- se queda el plan más antiguo, con la experiencia ya dada (la mayor) y los eventos y entregas de los demás.

WITH ranked AS (
    SELECT id,
           first_value(id) OVER (PARTITION BY usuario_id, semana_inicio ORDER BY creado_en, id) AS keep_id
    FROM planes_estudio
),
dupes AS (
    SELECT id, keep_id FROM ranked WHERE id <> keep_id
)
UPDATE horarios_academicos h
SET plan_estudio_id = d.keep_id
FROM dupes d
WHERE h.plan_estudio_id = d.id;

WITH ranked AS (
    SELECT id,
           first_value(id) OVER (PARTITION BY usuario_id, semana_inicio ORDER BY creado_en, id) AS keep_id
    FROM planes_estudio
),
dupes AS (
    SELECT id, keep_id FROM ranked WHERE id <> keep_id
)
UPDATE entregas_examenes e
SET plan_estudio_id = d.keep_id
FROM dupes d
WHERE e.plan_estudio_id = d.id;

UPDATE planes_estudio p
SET xp_planificacion_otorgado = agg.otorgado,
    xp_planificacion_puntos = agg.puntos
FROM (
    SELECT usuario_id, semana_inicio,
           bool_or(xp_planificacion_otorgado) AS otorgado,
           max(xp_planificacion_puntos) AS puntos
    FROM planes_estudio
    GROUP BY usuario_id, semana_inicio
    HAVING count(*) > 1
) agg
WHERE p.usuario_id = agg.usuario_id AND p.semana_inicio = agg.semana_inicio;

DELETE FROM planes_estudio p
USING (
    SELECT id,
           first_value(id) OVER (PARTITION BY usuario_id, semana_inicio ORDER BY creado_en, id) AS keep_id
    FROM planes_estudio
) r
WHERE p.id = r.id AND r.id <> r.keep_id;

CREATE UNIQUE INDEX ux_planes_estudio_usuario_semana ON planes_estudio (usuario_id, semana_inicio);
