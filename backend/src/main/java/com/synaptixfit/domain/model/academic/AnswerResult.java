package com.synaptixfit.domain.model.academic;

import java.util.List;
import java.util.UUID;

/**
 * Corrección de una respuesta. En «Varias correctas» {@code correctAnswer} lleva todas unidas (ver {@link Question}).
 * {@code dontKnow}: la persona dijo «No lo sé» (ADR 0063); entonces {@code correct} es falso y se enseña la solución.
 */
public record AnswerResult(UUID questionId, boolean correct, String correctAnswer, String explanation,
                           QuestionType type, boolean dontKnow) {

    public AnswerResult(UUID questionId, boolean correct, String correctAnswer, String explanation,
                        QuestionType type) {
        this(questionId, correct, correctAnswer, explanation, type, false);
    }

    /** Corrección de una respuesta dada a {@code q}. */
    public static AnswerResult graded(Question q, boolean correct) {
        return new AnswerResult(q.id(), correct, q.correctAnswer(), q.explanation(), q.type(), false);
    }

    /** «No lo sé» a {@code q}: fallo con la solución a la vista. */
    public static AnswerResult dontKnow(Question q) {
        return new AnswerResult(q.id(), false, q.correctAnswer(), q.explanation(), q.type(), true);
    }

    /** Respuestas correctas: una sola salvo en «Varias correctas». */
    public List<String> correctAnswers() {
        return type == QuestionType.MULTIPLE_ANSWER ? Question.splitAnswers(correctAnswer)
                : correctAnswer == null ? List.of() : List.of(correctAnswer);
    }
}
