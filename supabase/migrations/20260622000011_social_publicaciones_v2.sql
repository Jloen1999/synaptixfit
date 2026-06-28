-- ============================================================
-- Migración: Publicaciones sociales v2
-- 1) Amplía el CHECK `ck_actividad_tipo` para permitir publicaciones de
--    tipo 'rutina' y 'reto' (antes solo se aceptaban logros/sesiones, por lo
--    que insertar una publicación de rutina/reto violaba el constraint).
-- 2) Añade la columna `editado_en` para reflejar en la UI cuándo una
--    publicación ha sido editada por su autor (feedback visual "editado").
-- Idempotente.
-- ============================================================

ALTER TABLE public.actividades_sociales
    DROP CONSTRAINT IF EXISTS ck_actividad_tipo;

ALTER TABLE public.actividades_sociales
    ADD CONSTRAINT ck_actividad_tipo CHECK (
        tipo = ANY (ARRAY[
            'session_completed'::text,
            'challenge_completed'::text,
            'milestone_reached'::text,
            'badge_unlocked'::text,
            'rutina'::text,
            'reto'::text
        ])
    );

ALTER TABLE public.actividades_sociales
    ADD COLUMN IF NOT EXISTS editado_en timestamp with time zone;
