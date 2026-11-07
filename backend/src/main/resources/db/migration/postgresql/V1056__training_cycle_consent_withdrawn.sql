-- Seguimiento del ciclo (ADR 0033): además de cuándo se dio el consentimiento, cuándo se retiró (al desactivarlo),
-- como ya guarda el consentimiento de salud del registro diario (consentimientos_salud.retirado_en). Así se puede
-- demostrar el consentimiento y su retirada (art. 7.1 y 7.3 RGPD).
ALTER TABLE seguimiento_ciclo ADD COLUMN consentimiento_retirado_en timestamptz;
