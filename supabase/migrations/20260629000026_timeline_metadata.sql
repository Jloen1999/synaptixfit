-- Columnas de metadatos para items del timeline (clases principalmente)
ALTER TABLE horarios_academicos
  ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS tipo_clase VARCHAR;

COMMENT ON COLUMN horarios_academicos.is_private IS 'Si el evento es privado (visible solo para el dueño)';
COMMENT ON COLUMN horarios_academicos.tipo_clase IS 'Tipo de clase: teoria, practica';
