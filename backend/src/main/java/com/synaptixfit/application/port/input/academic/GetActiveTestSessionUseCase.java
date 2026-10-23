package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TestSessionView;
import java.util.Optional;
import java.util.UUID;

/** Sesión en curso de un material (para reanudarla), si existe. */
public interface GetActiveTestSessionUseCase {

    Optional<TestSessionView> findActiveSession(UUID userId, UUID materialId);
}
