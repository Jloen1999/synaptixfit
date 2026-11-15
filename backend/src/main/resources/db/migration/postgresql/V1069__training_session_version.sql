-- Bloqueo optimista de las sesiones (ADR 0047): con «Entrenamos juntos», la transacción de una persona pausa o
-- reanuda la sesión de otra. Sin versión, una escritura con la sesión leída antes podía pisar la otra (p. ej. borrar
-- una sesión recién terminada). Las filas existentes empiezan en 0.
ALTER TABLE sesiones_registradas ADD COLUMN version bigint NOT NULL DEFAULT 0;
