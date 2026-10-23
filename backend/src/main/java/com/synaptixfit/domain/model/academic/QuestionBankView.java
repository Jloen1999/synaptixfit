package com.synaptixfit.domain.model.academic;

import java.util.List;

/**
 * Banco con sus preguntas y estadísticas del usuario: preguntas con algún intento y preguntas
 * acertadas alguna vez.
 */
public record QuestionBankView(QuestionBank bank, List<Question> questions, int attemptedQuestions,
                               int correctQuestions) {

    public QuestionBankView {
        questions = List.copyOf(questions);
    }
}
