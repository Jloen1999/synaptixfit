package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TestSession;
import com.synaptixfit.domain.model.academic.TestSessionStatus;
import java.util.List;
import java.util.UUID;

/** Historial de sesiones de test con filtros opcionales. */
public interface ListTestSessionsUseCase {

    List<TestSession> listSessions(UUID userId, UUID materialId, TestSessionStatus status);
}
