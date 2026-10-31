-- Lenguaje sencillo: «check-in» pasa a «contar cómo estás».
UPDATE insignias
   SET descripcion = 'Cuenta cómo estás 7 días seguidos'
 WHERE criterio_tipo = 'checkins_consecutivos'
   AND descripcion = 'Completa 7 check-ins diarios consecutivos';
