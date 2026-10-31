-- Los avisos automáticos enviados antes de V900 no tenían código: se les pone a partir de su clave de
-- referencia o de su texto fijo, para que también se lean en el idioma de la app (ADR 0017). Solo se
-- tocan los que siguen sin código; los escritos a mano por la administración no encajan y se quedan igual.

UPDATE notificaciones
   SET codigo_mensaje = 'CHALLENGE_COMPLETED',
       parametros_mensaje = jsonb_build_object('name', substring(descripcion from '«(.*)»'))
 WHERE codigo_mensaje IS NULL AND clave_referencia LIKE 'challenge:%' AND descripcion LIKE '%«%»%';

UPDATE notificaciones
   SET codigo_mensaje = 'BADGE_EARNED',
       parametros_mensaje = jsonb_build_object('name', substring(descripcion from '«(.*)»'))
 WHERE codigo_mensaje IS NULL AND clave_referencia LIKE 'badge:%' AND descripcion LIKE '%«%»%';

UPDATE notificaciones
   SET codigo_mensaje = 'LEVEL_UP',
       parametros_mensaje = jsonb_build_object('level', substring(clave_referencia from 'level:(.*)'))
 WHERE codigo_mensaje IS NULL AND clave_referencia LIKE 'level:%';

UPDATE notificaciones
   SET codigo_mensaje = 'FATIGUE_CHECK_IN', parametros_mensaje = '{}'::jsonb
 WHERE codigo_mensaje IS NULL AND clave_referencia LIKE 'fatigue:check_in_adaptation:%';

UPDATE notificaciones
   SET codigo_mensaje = 'OVERTRAINING',
       parametros_mensaje = jsonb_build_object('ratio', substring(descripcion from 'es ([0-9]+[.,][0-9]+) veces'))
 WHERE codigo_mensaje IS NULL AND clave_referencia LIKE 'fatigue:overtraining:%'
   AND descripcion ~ 'es [0-9]+[.,][0-9]+ veces';

UPDATE notificaciones
   SET codigo_mensaje = 'POST_LIKED',
       parametros_mensaje = jsonb_build_object('name', substring(descripcion from '^(.*) ha dado me gusta a tu publicación$'))
 WHERE codigo_mensaje IS NULL AND tipo = 'social' AND titulo = 'Nuevo me gusta'
   AND descripcion ~ ' ha dado me gusta a tu publicación$';

UPDATE notificaciones
   SET codigo_mensaje = 'POST_COMMENTED',
       parametros_mensaje = jsonb_build_object('name', substring(descripcion from '^(.*) ha comentado tu publicación$'))
 WHERE codigo_mensaje IS NULL AND tipo = 'social' AND titulo = 'Nuevo comentario'
   AND descripcion ~ ' ha comentado tu publicación$';

UPDATE notificaciones
   SET codigo_mensaje = 'FRIEND_REQUEST_RECEIVED',
       parametros_mensaje = jsonb_build_object('name', substring(descripcion from '^(.*) quiere añadirte como amigo$'))
 WHERE codigo_mensaje IS NULL AND tipo = 'social' AND titulo = 'Nueva solicitud de amistad'
   AND descripcion ~ ' quiere añadirte como amigo$';

UPDATE notificaciones
   SET codigo_mensaje = 'FRIEND_REQUEST_ACCEPTED',
       parametros_mensaje = jsonb_build_object('name', substring(descripcion from '^(.*) ha aceptado tu solicitud de amistad$'))
 WHERE codigo_mensaje IS NULL AND tipo = 'social' AND titulo = 'Solicitud aceptada'
   AND descripcion ~ ' ha aceptado tu solicitud de amistad$';
