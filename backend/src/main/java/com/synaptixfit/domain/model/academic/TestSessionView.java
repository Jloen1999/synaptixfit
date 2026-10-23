package com.synaptixfit.domain.model.academic;

import java.util.List;

/** Sesión de test con sus preguntas (en el orden de la sesión) y la XP concedida en esta operación. */
public record TestSessionView(TestSession session, List<Question> questions, int xpAwarded) {

    public TestSessionView {
        questions = List.copyOf(questions);
    }
}
