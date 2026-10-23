package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** El banco de preguntas no existe o no es del usuario. */
public class QuestionBankNotFoundException extends ResourceNotFoundException {

    public QuestionBankNotFoundException(Object id) {
        super("QUIZ_BANK_NOT_FOUND", "Question bank", id);
    }
}
