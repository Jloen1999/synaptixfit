package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.Degree;
import java.util.UUID;

/** Una carrera del catálogo con su centro y universidad. */
public interface GetDegreeUseCase {

    Degree getDegree(UUID degreeId);
}
