package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.util.UUID;

/** Convierte un apunte o archivo propio en material de estudio (si ya lo es, devuelve el existente). */
public interface RegisterStudyMaterialUseCase {

    StudyMaterial registerMaterial(UUID userId, StudySourceType originType, UUID originId);
}
