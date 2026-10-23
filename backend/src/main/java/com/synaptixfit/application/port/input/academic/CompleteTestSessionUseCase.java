package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TestSessionView;
import java.util.UUID;

/** Completa una sesión en curso; si se respondieron todas las preguntas concede su XP una vez. */
public interface CompleteTestSessionUseCase {

    TestSessionView completeSession(UUID userId, UUID sessionId);
}
