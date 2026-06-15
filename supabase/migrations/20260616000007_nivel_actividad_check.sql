-- ============================================================
-- Migración 0007: Validación de nivel_actividad
-- Propósito: Añadir CHECK constraint a nivel_actividad
-- ============================================================

ALTER TABLE public.perfil_bienestar_usuario DROP CONSTRAINT IF EXISTS ck_nivel_actividad;

ALTER TABLE public.perfil_bienestar_usuario ADD CONSTRAINT ck_nivel_actividad
    CHECK (nivel_actividad = ANY (ARRAY['sedentario'::text, 'ligero'::text, 'moderado'::text, 'alto'::text]))
    NOT VALID;
