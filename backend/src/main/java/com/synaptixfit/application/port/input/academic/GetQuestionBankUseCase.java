package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.QuestionBankView;
import com.synaptixfit.domain.model.academic.QuestionType;
import java.util.Set;
import java.util.UUID;

/**
 * Banco de preguntas de un material propio con estadísticas del usuario, solo con los tipos que la app sabe
 * pintar (ADR 0058).
 */
public interface GetQuestionBankUseCase {

    QuestionBankView getBank(UUID userId, UUID materialId, Set<QuestionType> visibleTypes);

    default QuestionBankView getBank(UUID userId, UUID materialId) {
        return getBank(userId, materialId, QuestionType.ALL);
    }
}
