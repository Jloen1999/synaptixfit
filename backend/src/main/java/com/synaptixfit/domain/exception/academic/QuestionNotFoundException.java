package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ResourceNotFoundException;

/** La pregunta no existe, no es del usuario o no pertenece a la sesión. */
public class QuestionNotFoundException extends ResourceNotFoundException {

    public QuestionNotFoundException(Object id) {
        super("QUIZ_QUESTION_NOT_FOUND", "Question", id);
    }
}
