package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.BankUpdateMode;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import java.util.List;
import java.util.UUID;

/**
 * Guarda en el banco de un material las preguntas ya creadas por «Crear preguntas» (ADR 0058): las añade
 * sin repetir enunciados o sustituye las que había. Es el paso corto y transaccional; la IA va antes, fuera
 * de la transacción ({@link GenerateQuestionBankUseCase}).
 */
public interface SaveCreatedQuestionsUseCase {

    record Command(UUID userId, UUID materialId, BankUpdateMode mode, List<QuestionDraft> questions) {

        public Command {
            questions = List.copyOf(questions);
        }
    }

    /** Devuelve cuántas se guardaron (las repetidas no cuentan). */
    int saveCreatedQuestions(Command command);
}
