package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AnswerResult;
import java.util.UUID;

/**
 * «No lo sé» a una pregunta propia fuera de una sesión (práctica libre o la lista de «Practicar», ADR 0063):
 * registra un intento de la nota más baja y devuelve la solución.
 */
public interface DontKnowQuestionUseCase {

    AnswerResult dontKnow(UUID userId, UUID questionId);
}
