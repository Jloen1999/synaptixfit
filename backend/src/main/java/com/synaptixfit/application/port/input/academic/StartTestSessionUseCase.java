package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TestSessionView;
import java.util.List;
import java.util.UUID;

/** Crea una sesión de test con preguntas de uno o varios materiales, priorizando las falladas. */
public interface StartTestSessionUseCase {

    record Command(UUID userId, List<UUID> materialIds, Integer questionCount) {}

    TestSessionView startSession(Command command);
}
