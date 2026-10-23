package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.StudyMaterial;
import java.util.UUID;

/** Detalle de un material propio. */
public interface GetStudyMaterialUseCase {

    StudyMaterial getMaterial(UUID userId, UUID materialId);
}
