-- «Varias correctas» (ADR 0058): tipo nuevo de pregunta. Sus respuestas correctas van en respuesta_correcta,
-- una por línea y con el texto exacto de la opción; se corrige todo o nada en el servidor.
ALTER TABLE preguntas DROP CONSTRAINT preguntas_tipo_check;
ALTER TABLE preguntas ADD CONSTRAINT preguntas_tipo_check
    CHECK (tipo IN ('opcion_multiple', 'rellenar_hueco', 'varias_correctas'));
