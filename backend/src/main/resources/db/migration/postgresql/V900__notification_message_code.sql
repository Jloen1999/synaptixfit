-- Avisos automáticos traducibles: el cliente muestra su propio texto (en el idioma elegido) a partir
-- del código y sus datos. titulo y descripcion siguen guardándose en español como respaldo (avisos
-- antiguos y los escritos a mano por la administración, que no llevan código).
ALTER TABLE notificaciones ADD COLUMN codigo_mensaje VARCHAR(40);
ALTER TABLE notificaciones ADD COLUMN parametros_mensaje JSONB;
