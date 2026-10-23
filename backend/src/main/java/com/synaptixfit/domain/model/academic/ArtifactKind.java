package com.synaptixfit.domain.model.academic;

/** Qué genera el centro de generación multi-fuente. */
public enum ArtifactKind {
    SUMMARY,
    MIND_MAP,
    /** Tarjetas pregunta/respuesta. */
    FLASHCARDS,
    /** Test de práctica (opción múltiple y rellenar hueco) para el simulacro. */
    PRACTICE_TEST
}
