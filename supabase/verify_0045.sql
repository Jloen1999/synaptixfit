-- Ejecutar SOLO si la columna pesos_kg no existe
ALTER TABLE public.seleccion_de_ejercicios
  ADD COLUMN IF NOT EXISTS pesos_kg jsonb;
