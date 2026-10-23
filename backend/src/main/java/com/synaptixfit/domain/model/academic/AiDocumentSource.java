package com.synaptixfit.domain.model.academic;

/**
 * A qué se refiere un documento de IA: un apunte, un archivo o una asignatura (guía docente).
 * Junto con el id de la fuente y el tipo, identifica el documento de forma única por usuario.
 */
public enum AiDocumentSource {
    NOTE,
    FILE,
    SUBJECT;

    public static AiDocumentSource of(StudySourceType type) {
        return type == StudySourceType.NOTE ? NOTE : FILE;
    }
}
