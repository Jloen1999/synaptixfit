package com.synaptixfit.domain.model.academic;

import java.util.List;
import java.util.UUID;

/**
 * Qué se puede meter en un simulacro de una asignatura: los apuntes y archivos que ya tienen
 * preguntas y los límites que aplica el servidor al empezarlo (así el cliente no los repite).
 */
public record MockExamOptions(List<Source> sources, int maxMaterials, int suggestedQuestions, int maxQuestions) {

    /** Material con banco de preguntas y cuántas tiene. */
    public record Source(UUID materialId, String title, StudySourceType originType, int questionCount) {
    }

    public MockExamOptions {
        sources = sources == null ? List.of() : List.copyOf(sources);
    }
}
