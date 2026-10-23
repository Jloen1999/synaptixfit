-- Correlación entre módulos (estudio ↔ entrenamiento ↔ gamificación ↔ indicadores).

-- 1. Pomodoro: bloque y asignatura en los que se hizo (opcionales, informativos) y la XP exacta que
--    dio cada fase. La XP diaria del Pomodoro tiene tope (FocusRewards): se calcula sumando
--    xp_otorgado del día, así que el tope no depende de ningún contador aparte.
ALTER TABLE sesiones_focus
    ADD COLUMN bloque_id uuid REFERENCES horarios_academicos (id) ON DELETE SET NULL,
    ADD COLUMN asignatura_id uuid REFERENCES asignaturas (id) ON DELETE SET NULL,
    ADD COLUMN xp_otorgado integer NOT NULL DEFAULT 0 CHECK (xp_otorgado >= 0);

-- 2. Retos de fitness por sesiones (ADR 0009): objetivo opcional de sesiones de entrenamiento y
--    recuento de las completadas dentro del periodo del reto. El recuento se recalcula siempre desde
--    sesiones_registradas (idempotente); se guarda para listar el progreso sin leer otro módulo.
ALTER TABLE retos
    ADD COLUMN sesiones_objetivo integer CHECK (sesiones_objetivo IS NULL OR sesiones_objetivo BETWEEN 1 AND 365),
    ADD COLUMN sesiones_completadas integer NOT NULL DEFAULT 0 CHECK (sesiones_completadas >= 0);

CREATE INDEX idx_retos_usuario_sesiones ON retos (usuario_id) WHERE sesiones_objetivo IS NOT NULL;
