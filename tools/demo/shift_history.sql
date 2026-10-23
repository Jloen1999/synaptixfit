-- shift_history.sql — Lleva al pasado lo que los usuarios demo hicieron en una «ronda» del seed.
--
-- Cada día simulado, seed_demo.py hace las acciones por la API pública (así corren todas las reglas y
-- eventos del backend con la hora real) y después ejecuta este script. Solo cambia fechas: ninguna regla
-- de negocio. Lo derivado se recalcula leyendo del backend al final (ver README.md).
--
-- Dos tratamientos:
-- 1. Actividad que alimenta la racha y el ACWR (sesiones de entrenamiento, sus series y su carga física,
--    check-ins y Pomodoros): se «enrolla». Lo de esta ronda se deja hoy a la hora simulada (align) y después
--    TODO lo de los usuarios de la ejecución retrocede `roll` días (lo que falta hasta el siguiente día
--    simulado). Así, en cada ronda el backend ve los días anteriores justo antes de hoy y calcula racha,
--    insignias de constancia y ACWR igual que si el tiempo hubiera pasado. Tras la última ronda cada fila
--    queda en su fecha.
-- 2. Todo lo demás (filas con marca de tiempo >= t0): se lleva directamente a la fecha simulada (shift).
--
-- Variables (psql \set): t0 (inicio de la ronda), shift (intervalo, negativo), days (días enteros que
-- retroceden las columnas DATE), align (intervalo que lleva lo de hoy a la hora simulada), roll (días que
-- retrocede la actividad), today (fecha real, YYYY-MM-DD), target_day (fecha simulada) y users (emails
-- separados por comas; siempre del dominio demo).
--
-- No se mueven a propósito: fechas que el usuario elige (fecha límite de entregas, inicio y fin de retos,
-- horario de los bloques, semana de los planes, fecha de inicio de rutinas) ni los tokens de sesión.

\set ON_ERROR_STOP 1
SET TIME ZONE 'Europe/Madrid';
BEGIN;

CREATE TEMP TABLE demo_u ON COMMIT DROP AS
SELECT id FROM usuarios
WHERE email LIKE '%@demo.synaptixfit.test'
  AND email = ANY (string_to_array(:'users', ','));

-- Bloques de repaso SM-2 pendientes que la ronda creó o movió: siguen a la fecha del material
-- (el evento ReviewScheduled los colocó en la siguiente fecha SM-2 calculada con la hora real).
UPDATE horarios_academicos h
SET hora_inicio = h.hora_inicio + :'shift'::interval,
    hora_fin = h.hora_fin + :'shift'::interval,
    dia_semana = extract(isodow FROM h.hora_inicio + :'shift'::interval)::int
FROM materiales_estudio m
WHERE h.material_estudio_id = m.id
  AND h.usuario_id IN (SELECT id FROM demo_u)
  AND NOT h.completado
  AND (m.ultimo_repaso_en >= :'t0'::timestamptz OR m.creado_en >= :'t0'::timestamptz);

-- Material de estudio: la siguiente fecha de repaso se mueve si el repaso fue en esta ronda.
UPDATE materiales_estudio SET
  siguiente_repaso_en = CASE WHEN ultimo_repaso_en >= :'t0'::timestamptz
                             THEN siguiente_repaso_en + :'shift'::interval ELSE siguiente_repaso_en END,
  ultimo_repaso_en = CASE WHEN ultimo_repaso_en >= :'t0'::timestamptz
                          THEN ultimo_repaso_en + :'shift'::interval ELSE ultimo_repaso_en END,
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (ultimo_repaso_en >= :'t0'::timestamptz OR creado_en >= :'t0'::timestamptz);

-- Avisos de fatiga: la clave lleva el día («fatigue:<motivo>:<día>») para no repetirse; se lleva al día simulado.
UPDATE notificaciones
SET clave_referencia = replace(clave_referencia, :'today', :'target_day')
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND creado_en >= :'t0'::timestamptz
  AND clave_referencia LIKE 'fatigue:%';

UPDATE notificaciones SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  leida_en = CASE WHEN leida_en >= :'t0'::timestamptz THEN leida_en + :'shift'::interval ELSE leida_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR leida_en >= :'t0'::timestamptz);

-- Resto de tablas: marcas de tiempo de la ronda (>= t0) y columnas DATE de hoy.

UPDATE usuarios SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE perfil_bienestar_usuario SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE perfil_academico_usuario SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE historial_peso SET
  registrado_en = CASE WHEN registrado_en >= :'t0'::timestamptz THEN registrado_en + :'shift'::interval ELSE registrado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (registrado_en >= :'t0'::timestamptz);

UPDATE historial_objetivos SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  fecha_inicio = CASE WHEN fecha_inicio >= :'today'::date THEN fecha_inicio - :days ELSE fecha_inicio END,
  fecha_fin = CASE WHEN fecha_fin >= :'today'::date THEN fecha_fin - :days ELSE fecha_fin END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR fecha_inicio >= :'today'::date OR fecha_fin >= :'today'::date);

UPDATE usuario_carreras SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz);

UPDATE preferencias_notificacion SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE asignaturas SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  ultima_sincronizacion = CASE WHEN ultima_sincronizacion >= :'t0'::timestamptz THEN ultima_sincronizacion + :'shift'::interval ELSE ultima_sincronizacion END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR ultima_sincronizacion >= :'t0'::timestamptz);

UPDATE asignaturas_usuario_semestre SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz);

UPDATE apuntes SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE archivos_asignatura SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz);

UPDATE documentos_ia SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE bancos_preguntas SET
  generado_en = CASE WHEN generado_en >= :'t0'::timestamptz THEN generado_en + :'shift'::interval ELSE generado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (generado_en >= :'t0'::timestamptz);

UPDATE intentos_pregunta SET
  respondido_en = CASE WHEN respondido_en >= :'t0'::timestamptz THEN respondido_en + :'shift'::interval ELSE respondido_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (respondido_en >= :'t0'::timestamptz);

UPDATE test_sessions SET
  iniciado_en = CASE WHEN iniciado_en >= :'t0'::timestamptz THEN iniciado_en + :'shift'::interval ELSE iniciado_en END,
  completado_en = CASE WHEN completado_en >= :'t0'::timestamptz THEN completado_en + :'shift'::interval ELSE completado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (iniciado_en >= :'t0'::timestamptz OR completado_en >= :'t0'::timestamptz);

UPDATE registros_repaso_srs SET
  fecha_repaso = CASE WHEN fecha_repaso >= :'t0'::timestamptz THEN fecha_repaso + :'shift'::interval ELSE fecha_repaso END,
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE material_estudio_id IN (SELECT id FROM materiales_estudio WHERE usuario_id IN (SELECT id FROM demo_u))
  AND (fecha_repaso >= :'t0'::timestamptz OR creado_en >= :'t0'::timestamptz);

UPDATE horarios_academicos SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  asistencia_registrada_en = CASE WHEN asistencia_registrada_en >= :'t0'::timestamptz THEN asistencia_registrada_en + :'shift'::interval ELSE asistencia_registrada_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR asistencia_registrada_en >= :'t0'::timestamptz);

UPDATE entregas_examenes SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE planes_estudio SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE carga_academica_semanal SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE rutinas SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END,
  eliminado_en = CASE WHEN eliminado_en >= :'t0'::timestamptz THEN eliminado_en + :'shift'::interval ELSE eliminado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz OR eliminado_en >= :'t0'::timestamptz);

UPDATE semanas_rutina SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE rutina_id IN (SELECT id FROM rutinas WHERE usuario_id IN (SELECT id FROM demo_u))
  AND (creado_en >= :'t0'::timestamptz);

UPDATE dias_rutina SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE semana_id IN (SELECT s.id FROM semanas_rutina s JOIN rutinas r ON r.id = s.rutina_id WHERE r.usuario_id IN (SELECT id FROM demo_u))
  AND (creado_en >= :'t0'::timestamptz);

UPDATE plan_entrenamiento_semanal SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE recomendaciones_pendientes SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz);

UPDATE retos SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END,
  ultimo_dia_activo = CASE WHEN ultimo_dia_activo >= :'today'::date THEN ultimo_dia_activo - :days ELSE ultimo_dia_activo END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz OR ultimo_dia_activo >= :'today'::date);

UPDATE progreso_de_reto SET
  registrado_en = CASE WHEN registrado_en >= :'t0'::timestamptz THEN registrado_en + :'shift'::interval ELSE registrado_en END,
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (registrado_en >= :'t0'::timestamptz OR creado_en >= :'t0'::timestamptz);

UPDATE usuario_insignias SET
  obtenida_en = CASE WHEN obtenida_en >= :'t0'::timestamptz THEN obtenida_en + :'shift'::interval ELSE obtenida_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (obtenida_en >= :'t0'::timestamptz);

UPDATE actividades_sociales SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  editado_en = CASE WHEN editado_en >= :'t0'::timestamptz THEN editado_en + :'shift'::interval ELSE editado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR editado_en >= :'t0'::timestamptz);

UPDATE interacciones_sociales SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz);

UPDATE comentarios_feed SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  editado_en = CASE WHEN editado_en >= :'t0'::timestamptz THEN editado_en + :'shift'::interval ELSE editado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR editado_en >= :'t0'::timestamptz);

UPDATE amistades SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE (solicitante_id IN (SELECT id FROM demo_u) OR receptor_id IN (SELECT id FROM demo_u))
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

UPDATE estado_cognitivo_usuario SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END,
  fecha_ultimo_descanso = CASE WHEN fecha_ultimo_descanso >= :'t0'::timestamptz THEN fecha_ultimo_descanso + :'shift'::interval ELSE fecha_ultimo_descanso END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz OR fecha_ultimo_descanso >= :'t0'::timestamptz);

UPDATE estado_regulacion_cruzada SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'shift'::interval ELSE creado_en END,
  actualizado_en = CASE WHEN actualizado_en >= :'t0'::timestamptz THEN actualizado_en + :'shift'::interval ELSE actualizado_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR actualizado_en >= :'t0'::timestamptz);

-- Actividad (racha y ACWR): lo de esta ronda, a la hora simulada de hoy…
UPDATE sesiones_registradas SET
  creado_en = CASE WHEN creado_en >= :'t0'::timestamptz THEN creado_en + :'align'::interval ELSE creado_en END,
  completada_en = CASE WHEN completada_en >= :'t0'::timestamptz THEN completada_en + :'align'::interval ELSE completada_en END
WHERE usuario_id IN (SELECT id FROM demo_u)
  AND (creado_en >= :'t0'::timestamptz OR completada_en >= :'t0'::timestamptz);

UPDATE series_sesion SET creado_en = creado_en + :'align'::interval
WHERE sesion_id IN (SELECT id FROM sesiones_registradas WHERE usuario_id IN (SELECT id FROM demo_u))
  AND creado_en >= :'t0'::timestamptz;

UPDATE registros_carga_fisica SET creado_en = creado_en + :'align'::interval
WHERE usuario_id IN (SELECT id FROM demo_u) AND creado_en >= :'t0'::timestamptz;

UPDATE estado_diario_usuario SET creado_en = creado_en + :'align'::interval
WHERE usuario_id IN (SELECT id FROM demo_u) AND creado_en >= :'t0'::timestamptz;

UPDATE sesiones_focus SET creado_en = creado_en + :'align'::interval
WHERE usuario_id IN (SELECT id FROM demo_u) AND creado_en >= :'t0'::timestamptz;

-- …y toda la actividad de los usuarios de la ejecución retrocede `roll` días (la hora local se conserva).
UPDATE sesiones_registradas SET
  creado_en = creado_en - make_interval(days => :roll),
  completada_en = completada_en - make_interval(days => :roll)
WHERE usuario_id IN (SELECT id FROM demo_u);

UPDATE series_sesion SET creado_en = creado_en - make_interval(days => :roll)
WHERE sesion_id IN (SELECT id FROM sesiones_registradas WHERE usuario_id IN (SELECT id FROM demo_u));

UPDATE registros_carga_fisica SET
  fecha_registro = fecha_registro - :roll,
  creado_en = creado_en - make_interval(days => :roll)
WHERE usuario_id IN (SELECT id FROM demo_u);

-- estado_diario_usuario tiene UNIQUE (usuario_id, fecha): se mueve en dos pasos para no chocar a mitad.
UPDATE estado_diario_usuario SET fecha = fecha - 100000 WHERE usuario_id IN (SELECT id FROM demo_u);
UPDATE estado_diario_usuario SET
  fecha = fecha + 100000 - :roll,
  creado_en = creado_en - make_interval(days => :roll)
WHERE usuario_id IN (SELECT id FROM demo_u);

UPDATE sesiones_focus SET
  fecha = fecha - :roll,
  creado_en = creado_en - make_interval(days => :roll)
WHERE usuario_id IN (SELECT id FROM demo_u);

COMMIT;
