package com.synaptixfit.domain.model.academic;

import java.util.List;

/**
 * Resultado efímero del centro de generación: no se guarda. El cliente puede guardarlo después
 * como apunte (resumen o mapa) o como banco de preguntas (tarjetas o test).
 */
public record GeneratedStudyArtifact(ArtifactKind kind, String title, String markdown, MindMap mindMap,
                                     List<Flashcard> flashcards, List<QuestionDraft> questions) {

    /** Tarjeta de estudio pregunta/respuesta. */
    public record Flashcard(String question, String answer) {
    }

    public GeneratedStudyArtifact {
        flashcards = flashcards == null ? List.of() : List.copyOf(flashcards);
        questions = questions == null ? List.of() : List.copyOf(questions);
    }
}
