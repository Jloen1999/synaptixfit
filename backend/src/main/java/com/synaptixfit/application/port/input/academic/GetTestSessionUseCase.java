package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TestSessionView;
import java.util.UUID;

/** Sesión de test propia con sus preguntas. */
public interface GetTestSessionUseCase {

    TestSessionView getSession(UUID userId, UUID sessionId);
}
