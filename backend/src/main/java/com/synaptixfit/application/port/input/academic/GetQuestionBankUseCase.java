package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.QuestionBankView;
import java.util.UUID;

/** Banco de preguntas de un material propio con estadísticas del usuario. */
public interface GetQuestionBankUseCase {

    QuestionBankView getBank(UUID userId, UUID materialId);
}
