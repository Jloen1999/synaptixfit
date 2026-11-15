-- «Entrenamos juntos» a la vez (ADR 0047): hora de inicio común y pausa del grupo.
-- empezado_en / empezado_por: la pone el primer «Empezar» de cualquiera de dentro; es la hora de inicio de la sesión
-- de cada persona. Quién empezó solo se usa para el aviso «Ana ha empezado».
-- pausado_en / pausado_por: pausa del grupo en curso y quién la puso (solo se enseña su nombre).
ALTER TABLE entrenos_juntos ADD COLUMN empezado_en timestamptz;
ALTER TABLE entrenos_juntos ADD COLUMN empezado_por uuid REFERENCES usuarios (id) ON DELETE SET NULL;
ALTER TABLE entrenos_juntos ADD COLUMN pausado_en timestamptz;
ALTER TABLE entrenos_juntos ADD COLUMN pausado_por uuid REFERENCES usuarios (id) ON DELETE SET NULL;
