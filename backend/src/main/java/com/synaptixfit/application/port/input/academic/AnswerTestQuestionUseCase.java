package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SessionAnswer;
import java.util.UUID;

/**
 * Responde una pregunta de una sesión en curso (corrige, registra el intento y guarda el progreso). Con
 * {@code dontKnow} la respuesta es «No lo sé» (ADR 0063): fallo con la solución a la vista y la pregunta vuelve antes.
 */
public interface AnswerTestQuestionUseCase {

    record Command(UUID userId, UUID sessionId, UUID questionId, String answer, Integer nextIndex,
                   boolean dontKnow) {

        public Command(UUID userId, UUID sessionId, UUID questionId, String answer, Integer nextIndex) {
            this(userId, sessionId, questionId, answer, nextIndex, false);
        }
    }

    SessionAnswer answer(Command command);
}
