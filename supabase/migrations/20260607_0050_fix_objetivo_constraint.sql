-- =============================================================================
-- 0050: Reemplazar constraint legacy de objetivo_principal en perfil_bienestar_usuario
-- La constraint antigua (ck_perfil_objetivo) solo aceptaba valores legacy:
-- 'perder_peso', 'ganar_masa', 'fitness_general', 'fuerza', 'resistencia', 'movilidad'
-- Se actualizan los registros existentes y se añade nueva constraint con finalidadesEstandar.
-- =============================================================================

-- 1. Eliminar constraint antigua
ALTER TABLE public.perfil_bienestar_usuario
  DROP CONSTRAINT IF EXISTS ck_perfil_objetivo;

-- 2. Migrar valores legacy a los nuevos estándar
UPDATE public.perfil_bienestar_usuario
  SET objetivo_principal = 'Hipertrofia Muscular'
  WHERE objetivo_principal IN ('ganar_masa', 'mixto', 'hipertrofia');

UPDATE public.perfil_bienestar_usuario
  SET objetivo_principal = 'Fuerza Máxima'
  WHERE objetivo_principal IN ('fuerza');

UPDATE public.perfil_bienestar_usuario
  SET objetivo_principal = 'Acondicionamiento Metabólico'
  WHERE objetivo_principal IN ('perder_peso', 'cardio');

UPDATE public.perfil_bienestar_usuario
  SET objetivo_principal = 'Fuerza Resistencia'
  WHERE objetivo_principal IN ('resistencia');

UPDATE public.perfil_bienestar_usuario
  SET objetivo_principal = 'Movilidad y Flexibilidad'
  WHERE objetivo_principal IN ('movilidad', 'flexibilidad');

UPDATE public.perfil_bienestar_usuario
  SET objetivo_principal = 'Estabilidad y Control Motor'
  WHERE objetivo_principal IN ('fitness_general');

-- 3. Añadir nueva constraint con los valores estándar
ALTER TABLE public.perfil_bienestar_usuario
  ADD CONSTRAINT ck_perfil_objetivo_estandar CHECK (
    objetivo_principal IN (
      'Hipertrofia Muscular',
      'Fuerza Máxima',
      'Potencia y Explosividad',
      'Fuerza Resistencia',
      'Movilidad y Flexibilidad',
      'Estabilidad y Control Motor',
      'Acondicionamiento Metabólico'
    )
  );
