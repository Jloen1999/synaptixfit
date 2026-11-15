-- ADR 0042. «Pausar racha»: los días en pausa sin actividad ni suman ni cortan la racha. Solo se guardan las
-- fechas (sin motivo: ningún dato de salud). Los topes (7 días seguidos, 14 en 90) los aplica el dominio
-- (StreakPause), no la base de datos. Se borra con la cuenta.
CREATE TABLE pausas_racha (
    id uuid PRIMARY KEY,
    usuario_id uuid NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    desde date NOT NULL,
    hasta date NOT NULL,
    creado_en timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT ck_pausas_racha_fechas CHECK (hasta >= desde)
);

-- Una pausa por persona y día de inicio: dos «Pausar racha» a la vez no crean dos pausas solapadas.
CREATE UNIQUE INDEX uq_pausas_racha_usuario_desde ON pausas_racha (usuario_id, desde);
