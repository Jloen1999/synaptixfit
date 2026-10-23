package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.Degree;
import java.util.List;
import java.util.UUID;

/** Carreras de una universidad (de todos sus centros) o de un centro concreto. */
public interface ListDegreesUseCase {

    List<Degree> listDegreesByUniversity(UUID universityId, String query);

    List<Degree> listDegreesByCenter(UUID centerId);
}
