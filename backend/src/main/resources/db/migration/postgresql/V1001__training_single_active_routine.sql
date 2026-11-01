-- Entrenamiento: una sola rutina en curso por usuario.
--
-- Antes podía haber varias rutinas activas y el «próximo entrenamiento» salía de la creada más
-- recientemente (duplicar o clonar cambiaba la rutina en curso sin avisar). Desde ahora activar una
-- rutina pausa la anterior (RoutineLifecycle). Aquí se deja activa solo la más reciente de cada
-- usuario, que es la que ya se mostraba como en curso; las demás pasan a 'pausado' sin perder avance.

UPDATE rutinas r
SET estado = 'pausado', actualizado_en = now()
WHERE r.estado = 'activo'
  AND r.eliminado_en IS NULL
  AND EXISTS (SELECT 1
              FROM rutinas o
              WHERE o.usuario_id = r.usuario_id
                AND o.estado = 'activo'
                AND o.eliminado_en IS NULL
                AND (o.creado_en > r.creado_en OR (o.creado_en = r.creado_en AND o.id > r.id)));
