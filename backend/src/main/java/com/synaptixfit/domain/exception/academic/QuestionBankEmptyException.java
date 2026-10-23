package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** No hay preguntas con las que crear la sesión o la práctica. */
public class QuestionBankEmptyException extends BusinessRuleException {

    public QuestionBankEmptyException(Object id) {
        super("QUIZ_BANK_EMPTY", "No questions available for " + id);
    }
}
