package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.QuestionBankView;
import java.util.UUID;

/** Genera con IA las preguntas del banco del material (sustituye las anteriores). */
public interface GenerateQuestionBankUseCase {

    QuestionBankView generateBank(UUID userId, UUID materialId);
}
