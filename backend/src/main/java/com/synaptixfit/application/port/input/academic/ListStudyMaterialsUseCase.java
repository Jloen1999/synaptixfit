package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.util.List;
import java.util.UUID;

/** Materiales propios con filtros opcionales por asignatura u origen. */
public interface ListStudyMaterialsUseCase {

    record Query(UUID userId, UUID subjectId, StudySourceType originType, UUID originId) {}

    List<StudyMaterial> listMaterials(Query query);
}
