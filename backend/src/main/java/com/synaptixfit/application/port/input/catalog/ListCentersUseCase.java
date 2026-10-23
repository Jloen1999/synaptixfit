package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.Center;
import java.util.List;
import java.util.UUID;

/** Centros de una universidad. */
public interface ListCentersUseCase {

    List<Center> listCenters(UUID universityId);
}
