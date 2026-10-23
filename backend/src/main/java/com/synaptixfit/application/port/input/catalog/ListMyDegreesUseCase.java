package com.synaptixfit.application.port.input.catalog;

import com.synaptixfit.domain.model.catalog.UserDegree;
import java.util.List;
import java.util.UUID;

/** Carreras vinculadas por el usuario. */
public interface ListMyDegreesUseCase {

    List<UserDegree> listMyDegrees(UUID userId);
}
