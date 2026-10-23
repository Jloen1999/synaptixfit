package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TestSessionView;
import java.util.UUID;

/** Abandona una sesión en curso. */
public interface AbandonTestSessionUseCase {

    TestSessionView abandonSession(UUID userId, UUID sessionId);
}
