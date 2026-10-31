-- Los avisos de insignia nueva enlazaban al perfil; ahora llevan a la pantalla de insignias.
UPDATE notificaciones
   SET url_accion = '/progress/badges'
 WHERE clave_referencia LIKE 'badge:%'
   AND url_accion = '/profile';
