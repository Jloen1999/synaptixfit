package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.ConflictException;

/**
 * La pregunta de la sesión ya tiene resultado (respuesta o «No lo sé»): con la solución a la vista no se puede
 * cambiar, porque subiría la nota y la XP (ADR 0063).
 */
public class QuestionAlreadyAnsweredException extends ConflictException {

    public QuestionAlreadyAnsweredException(Object questionId) {
        super("QUIZ_QUESTION_ALREADY_ANSWERED", "Question " + questionId + " already has a result in this session");
    }
}
