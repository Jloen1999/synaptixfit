package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.UserDegree;
import java.util.UUID;

/** Vincula una carrera del catálogo al usuario. Idempotente. */
public interface LinkDegreeUseCase {

    UserDegree linkDegree(UUID userId, UUID degreeId);
}
