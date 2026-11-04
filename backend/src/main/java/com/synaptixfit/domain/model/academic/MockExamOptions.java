package com.synaptixfit.domain.model.academic;

import java.util.List;
import java.util.UUID;

/**
 * Qué se puede meter en un simulacro de una asignatura: los apuntes y archivos que ya tienen
 * preguntas y los límites que aplica el servidor al empezarlo (así el cliente no los repite).
 */
public record MockExamOptions(List<Source> sources, int maxMaterials, int suggestedQuestions, int maxQuestions) {

    /** Materiales que caben en un simulacro: más diluye tanto cada tema que no da para repasarlo. */
    public static final int MAX_MATERIALS = 10;

    /** Preguntas si la persona no elige: un simulacro corto, de unos 15 minutos. */
    public static final int DEFAULT_QUESTIONS = 10;

    /** Preguntas propuestas al mezclar varios materiales (≈ 30 minutos). */
    public static final int SUGGESTED_QUESTIONS = 20;

    /** Tope de preguntas: más de 50 seguidas ya no se responden con atención. */
    public static final int MAX_QUESTIONS = 50;

    /** Opciones con los límites de la regla. */
    public static MockExamOptions of(List<Source> sources) {
        return new MockExamOptions(sources, MAX_MATERIALS, SUGGESTED_QUESTIONS, MAX_QUESTIONS);
    }

    /** Material con banco de preguntas y cuántas tiene. */
    public record Source(UUID materialId, String title, StudySourceType originType, int questionCount) {
    }

    public MockExamOptions {
        sources = sources == null ? List.of() : List.copyOf(sources);
    }
}
