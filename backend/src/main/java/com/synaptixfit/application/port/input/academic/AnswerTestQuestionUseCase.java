package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.SessionAnswer;
import java.util.UUID;

/** Responde una pregunta de una sesión en curso (corrige, registra el intento y guarda el progreso). */
public interface AnswerTestQuestionUseCase {

    record Command(UUID userId, UUID sessionId, UUID questionId, String answer, Integer nextIndex) {}

    SessionAnswer answer(Command command);
}
