package com.synaptixfit.domain.model.academic;

import java.util.UUID;

/** Corrección de una respuesta. */
public record AnswerResult(UUID questionId, boolean correct, String correctAnswer, String explanation) {
}
