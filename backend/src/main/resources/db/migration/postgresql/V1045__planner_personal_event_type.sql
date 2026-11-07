-- Planificador: nuevo tipo de evento «personal» (ADR 0035) para el día a día que no es ni estudio ni deporte
-- (médico, trabajo, recados…). Su nombre va en «temas». Las reglas (sin XP, sin carga de estudio, visible con
-- cualquier modo de uso) viven en ActivityType; aquí solo se amplía la lista de códigos admitidos.
ALTER TABLE horarios_academicos DROP CONSTRAINT ck_horarios_tipo_actividad;

ALTER TABLE horarios_academicos
    ADD CONSTRAINT ck_horarios_tipo_actividad CHECK (tipo_actividad IN ('estudio', 'deporte', 'clase', 'descanso',
        'comida', 'sueno', 'examen', 'entrega', 'repaso', 'personal'));
