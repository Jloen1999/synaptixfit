-- ============================================================
-- Migración: Procedencia de clones/reutilizaciones (rutinas y retos)
-- Modelo: "copia independiente + referencia al origen".
--   - El clon/reutilización es 100% editable y NO afecta al original.
--   - Guardamos una referencia BLANDA al origen (sin FK) para que el clon
--     sobreviva aunque el original se elimine, y para mostrar la distinción
--     visual "Reutilizada de @propietario".
-- Columnas:
--   origen_id                 -> id de la entidad original (rutina/reto)
--   origen_propietario_id     -> id del usuario propietario original
--   origen_propietario_nombre -> nombre cacheado del propietario original
-- Idempotente.
-- ============================================================

ALTER TABLE public.rutinas
    ADD COLUMN IF NOT EXISTS origen_id uuid,
    ADD COLUMN IF NOT EXISTS origen_propietario_id uuid,
    ADD COLUMN IF NOT EXISTS origen_propietario_nombre text;

ALTER TABLE public.retos
    ADD COLUMN IF NOT EXISTS origen_id uuid,
    ADD COLUMN IF NOT EXISTS origen_propietario_id uuid,
    ADD COLUMN IF NOT EXISTS origen_propietario_nombre text;
