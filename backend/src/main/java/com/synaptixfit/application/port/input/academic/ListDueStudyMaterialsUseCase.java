package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.StudyMaterial;
import java.util.List;
import java.util.UUID;

/** Materiales con el repaso vencido, el más urgente primero. */
public interface ListDueStudyMaterialsUseCase {

    List<StudyMaterial> listDue(UUID userId, int limit);
}
