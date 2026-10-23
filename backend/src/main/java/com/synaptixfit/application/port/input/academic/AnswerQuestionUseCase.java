package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AnswerResult;
import java.util.UUID;

/** Corrige una respuesta a una pregunta propia y registra el intento. */
public interface AnswerQuestionUseCase {

    AnswerResult answerQuestion(UUID userId, UUID questionId, String answer);
}
