package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.TestSessionView;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Crea una sesión de test con preguntas de uno o varios materiales, priorizando las falladas. Solo entran
 * los tipos que sabe pintar la app (ADR 0058).
 */
public interface StartTestSessionUseCase {

    record Command(UUID userId, List<UUID> materialIds, Integer questionCount, Set<QuestionType> supportedTypes) {

        public Command {
            supportedTypes = supportedTypes == null ? QuestionType.ALL : Set.copyOf(supportedTypes);
        }

        public Command(UUID userId, List<UUID> materialIds, Integer questionCount) {
            this(userId, materialIds, questionCount, QuestionType.ALL);
        }
    }

    TestSessionView startSession(Command command);
}
