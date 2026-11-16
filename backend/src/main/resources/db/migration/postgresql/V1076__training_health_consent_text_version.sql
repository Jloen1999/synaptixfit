-- Versión del texto del consentimiento de salud que se aceptó (ADR 0054). La versión 2 dice que también cubre el
-- peso del perfil para proponer el peso de partida; los consentimientos que ya había son de la versión 1 y no cubren
-- ese uso hasta que se vuelva a aceptar el texto nuevo.
ALTER TABLE consentimientos_salud ADD COLUMN version_texto integer NOT NULL DEFAULT 1 CHECK (version_texto >= 1);
