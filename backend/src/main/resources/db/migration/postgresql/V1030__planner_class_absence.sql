-- Clases dadas por asistidas solas (ADR 0029): una clase que termina se completa sola; «No fui» la desmarca y
-- deja aquí constancia de la ausencia para que no vuelva a completarse. Volver a marcarla la borra.
ALTER TABLE horarios_academicos ADD COLUMN ausente BOOLEAN NOT NULL DEFAULT FALSE;

-- La búsqueda periódica de clases que acaban de terminar mira solo las clases sin completar y sin ausencia.
CREATE INDEX idx_horarios_clases_por_asistir ON horarios_academicos (hora_fin)
    WHERE tipo_actividad = 'clase' AND completado = FALSE AND ausente = FALSE;
