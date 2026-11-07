-- Vocabulario: lo que hay en el calendario se llama «evento» (o por su tipo), nunca «bloque».
UPDATE insignias
   SET descripcion = 'Completa 20 eventos de estudio'
 WHERE criterio_tipo = 'bloques_estudio'
   AND descripcion = 'Completa 20 bloques de estudio';
