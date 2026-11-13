-- La insignia «Planificador nato» cuenta los planes de la semana (planes_estudio). Desde el ADR 0038 no hay
-- botón «Cerrar semana»: el plan se crea cuando la semana da su XP de planificar (3 eventos planificados en
-- la semana actual o la siguiente). El texto dice ahora lo que hay que hacer, sin hablar de «planes».
UPDATE insignias
   SET descripcion = 'Planifica 3 semanas'
 WHERE criterio_tipo = 'planes_estudio'
   AND descripcion = 'Crea 3 planes de estudio';
