package com.synaptixfit.domain.model.academic;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/** Intento de respuesta a una pregunta (alimenta la priorización de preguntas falladas). */
public record QuestionAttempt(UUID id, UUID userId, UUID questionId, boolean correct, Instant answeredAt) {

    public QuestionAttempt {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(questionId, "questionId");
        Objects.requireNonNull(answeredAt, "answeredAt");
    }

    public static QuestionAttempt of(UUID userId, UUID questionId, boolean correct, Instant now) {
        return new QuestionAttempt(UUID.randomUUID(), userId, questionId, correct, now);
    }
}
