-- Indicadores (neurofisiología): criterio coherente del ACWR y carga física idempotente por sesión.
--
-- 1) ACWR. El sistema heredado (recalcular_regulacion_cruzada) guardaba en carga_aguda_7d la SUMA
--    de carga de 8 días (fecha >= hoy - 7) y en carga_cronica_28d la MEDIA diaria de 28 días, de modo
--    que acwr_actual = aguda / crónica salía ~7 veces mayor que el ACWR real (Gabbett, 2016).
--    Decisión: ambas columnas pasan a ser MEDIAS DIARIAS (AU/día) con ventanas que terminan hoy
--    incluido (7 y 28 días). Se mantiene la columna generada acwr_actual = aguda / crónica, que así
--    coincide con CrossRegulation.acwr (media 7d / media 28d) y queda acotada a [0, 4], dentro de
--    numeric(4,2). El backend recalcula la fila en cada lectura y tras cada sesión.
--    Los valores antiguos se convierten de forma aproximada (la suma se pasa a media diaria).
UPDATE estado_regulacion_cruzada
   SET carga_aguda_7d = round(carga_aguda_7d / 7.0, 2)
 WHERE carga_aguda_7d IS NOT NULL;

COMMENT ON COLUMN estado_regulacion_cruzada.carga_aguda_7d IS
    'Media diaria de carga (RPE x minutos) de los últimos 7 días, hoy incluido.';
COMMENT ON COLUMN estado_regulacion_cruzada.carga_cronica_28d IS
    'Media diaria de carga (RPE x minutos) de los últimos 28 días, hoy incluido.';
COMMENT ON COLUMN estado_regulacion_cruzada.acwr_actual IS
    'ACWR = media diaria 7d / media diaria 28d (null sin carga crónica).';

-- 2) Una sesión genera como máximo un registro de carga (idempotencia del evento
--    TrainingSessionCompletionChanged). Se eliminan duplicados heredados y se sustituye el índice
--    no único por uno único parcial.
DELETE FROM registros_carga_fisica a
 USING registros_carga_fisica b
 WHERE a.sesion_id IS NOT NULL
   AND a.sesion_id = b.sesion_id
   AND (a.creado_en, a.id) > (b.creado_en, b.id);

DROP INDEX IF EXISTS idx_carga_fisica_sesion;
CREATE UNIQUE INDEX ux_carga_fisica_sesion ON registros_carga_fisica USING btree (sesion_id)
    WHERE sesion_id IS NOT NULL;
