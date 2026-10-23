package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.University;
import java.util.UUID;

/** Una universidad del catálogo. */
public interface GetUniversityUseCase {

    University getUniversity(UUID universityId);
}
