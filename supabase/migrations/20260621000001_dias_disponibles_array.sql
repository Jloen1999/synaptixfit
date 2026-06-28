-- Migración: Transiciona dias_disponibles_semana (integer) a dias_disponibles (integer[])
-- Representa los días específicos de la semana (1=Lun, 2=Mar, ..., 7=Dom)
-- en lugar de una cantidad genérica.

BEGIN;

-- 1. Añadir nueva columna dias_disponibles como integer[] con valor por defecto
ALTER TABLE public.perfil_bienestar_usuario
ADD COLUMN IF NOT EXISTS dias_disponibles integer[] DEFAULT '{1,3,5}'::integer[];

-- 2. Migrar datos existentes: mapear la cantidad antigua a un array de días específicos
--    La heurística distribuye los días de manera equilibrada en la semana:
--    1 día → {3} (Miércoles, día central)
--    2 días → {1,4} (Lun, Jue)
--    3 días → {1,3,5} (Lun, Mié, Vie)
--    4 días → {1,2,4,5} (Lun, Mar, Jue, Vie)
--    5 días → {1,2,3,4,5} (Lun-Vie)
--    6 días → {1,2,3,4,5,6} (Lun-Sáb)
--    7 días → {1,2,3,4,5,6,7} (Lun-Dom)
UPDATE public.perfil_bienestar_usuario
SET dias_disponibles = CASE dias_disponibles_semana
    WHEN 1 THEN '{3}'::integer[]
    WHEN 2 THEN '{1,4}'::integer[]
    WHEN 3 THEN '{1,3,5}'::integer[]
    WHEN 4 THEN '{1,2,4,5}'::integer[]
    WHEN 5 THEN '{1,2,3,4,5}'::integer[]
    WHEN 6 THEN '{1,2,3,4,5,6}'::integer[]
    WHEN 7 THEN '{1,2,3,4,5,6,7}'::integer[]
    ELSE '{1,3,5}'::integer[]
END
WHERE dias_disponibles IS NULL;

-- 3. NOTA: Mantenemos dias_disponibles_semana para compatibilidad con código heredado.
--    Se eliminará en una migración futura cuando todos los clientes estén actualizados.

COMMIT;
