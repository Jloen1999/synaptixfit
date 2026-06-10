-- Añadir tracking de racha diaria a la tabla retos
ALTER TABLE public.retos
  ADD COLUMN IF NOT EXISTS racha_actual  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS mejor_racha   INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ultimo_dia_activo DATE;
