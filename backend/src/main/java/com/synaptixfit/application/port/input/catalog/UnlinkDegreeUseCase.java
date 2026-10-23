package com.synaptixfit.application.port.input.catalog;

import java.util.UUID;

/** Desvincula una carrera del usuario. Idempotente. */
public interface UnlinkDegreeUseCase {

    void unlinkDegree(UUID userId, UUID degreeId);
}
