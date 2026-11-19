package com.synaptixfit.domain.model.academic;

import java.util.List;
import java.util.UUID;

/** Corrección de una respuesta. En «Varias correctas» {@code correctAnswer} lleva todas unidas (ver {@link Question}). */
public record AnswerResult(UUID questionId, boolean correct, String correctAnswer, String explanation,
                           QuestionType type) {

    /** Respuestas correctas: una sola salvo en «Varias correctas». */
    public List<String> correctAnswers() {
        return type == QuestionType.MULTIPLE_ANSWER ? Question.splitAnswers(correctAnswer)
                : correctAnswer == null ? List.of() : List.of(correctAnswer);
    }
}
