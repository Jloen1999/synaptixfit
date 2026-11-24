package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Intento de respuesta a una pregunta: alimenta el orden en que vuelven las preguntas ({@link QuestionStanding})
 * y la nota que se propone al repasar ({@link PracticeScore}). Un «No lo sé» ({@code dontKnow}, ADR 0063) es un
 * intento fallado de la calidad más baja.
 */
public record QuestionAttempt(UUID id, UUID userId, UUID questionId, boolean correct, boolean dontKnow,
                              Instant answeredAt) {

    public QuestionAttempt {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(questionId, "questionId");
        Objects.requireNonNull(answeredAt, "answeredAt");
        if (dontKnow) {
            correct = false;
        }
    }

    public QuestionAttempt(UUID id, UUID userId, UUID questionId, boolean correct, Instant answeredAt) {
        this(id, userId, questionId, correct, false, answeredAt);
    }

    public static QuestionAttempt of(UUID userId, UUID questionId, boolean correct, Instant now) {
        return new QuestionAttempt(UUID.randomUUID(), userId, questionId, correct, false, now);
    }

    /** «No lo sé»: cuenta como fallo y la pregunta vuelve la primera. */
    public static QuestionAttempt dontKnow(UUID userId, UUID questionId, Instant now) {
        return new QuestionAttempt(UUID.randomUUID(), userId, questionId, false, true, now);
    }
}
