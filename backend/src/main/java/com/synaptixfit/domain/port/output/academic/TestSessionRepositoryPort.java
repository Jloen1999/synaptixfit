package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de sesiones de test. */
public interface TestSessionRepositoryPort {

    Optional<TestSession> findByIdAndUser(UUID id, UUID userId);

    /** Sesión en curso más reciente del material. */
    Optional<TestSession> findActive(UUID userId, UUID materialId);

    /** Sesiones del usuario (filtros opcionales), las más recientes primero. */
    List<TestSession> findByUser(UUID userId, UUID materialId, TestSessionStatus status);

    TestSession save(TestSession session);
}
