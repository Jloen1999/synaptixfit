-- Una tarea de reto (o un reto) puede vincularse a un día de rutina (ADR 0032): se completa sola al
-- entrenar ese día. El tipo nuevo es «dia_rutina»; «bloque» se mantiene por los datos antiguos.
ALTER TABLE hitos_de_reto DROP CONSTRAINT IF EXISTS ck_hitos_entidad_tipo;
ALTER TABLE hitos_de_reto ADD CONSTRAINT ck_hitos_entidad_tipo CHECK (
    entidad_vinculada_tipo IS NULL OR entidad_vinculada_tipo IN ('examen', 'entrega', 'bloque', 'dia_rutina'));

ALTER TABLE retos DROP CONSTRAINT IF EXISTS ck_retos_entidad_tipo;
ALTER TABLE retos ADD CONSTRAINT ck_retos_entidad_tipo CHECK (
    entidad_vinculada_tipo IS NULL OR entidad_vinculada_tipo IN ('examen', 'entrega', 'bloque', 'dia_rutina'));
