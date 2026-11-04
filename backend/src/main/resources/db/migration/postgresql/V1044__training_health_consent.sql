-- Consentimiento expreso para el registro diario (ADR 0034): sueño, energía, agujetas y dolor son datos de salud
-- (art. 9 RGPD) y no se mezclan con aceptar la política. Una fila por persona: cuándo lo dio y, si lo retiró,
-- cuándo. Se borra en cascada al eliminar la cuenta.
CREATE TABLE consentimientos_salud (
    usuario_id uuid PRIMARY KEY REFERENCES usuarios (id) ON DELETE CASCADE,
    consentido_en timestamptz NOT NULL,
    retirado_en timestamptz
);
