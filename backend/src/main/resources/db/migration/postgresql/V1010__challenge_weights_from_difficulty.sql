-- Retos: el peso de cada tarea pasa a derivarse de su dificultad (ADR 0028).
--
-- Antes había «pesos manuales» que debían sumar 100 y no cambiaban la XP: dos medidas paralelas de la
-- misma importancia. Ahora peso = XP de la dificultad de la tarea / suma de las de su reto × 100
-- (baja 20, media 40, alta 70). El dominio lo recalcula al cargar el reto; esta migración deja los datos
-- guardados coherentes con esa regla. Solo cambia la barra de progreso: ni el estado ni la XP.

UPDATE hitos_de_reto
SET porcentaje_peso = round(
        (CASE dificultad WHEN 'baja' THEN 20 WHEN 'alta' THEN 70 ELSE 40 END) * 10000.0
        / (SELECT sum(CASE x.dificultad WHEN 'baja' THEN 20 WHEN 'alta' THEN 70 ELSE 40 END)
           FROM hitos_de_reto x
           WHERE x.reto_id = hitos_de_reto.reto_id)
    ) / 100.0;
