package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.StudyMaterial;
import java.util.UUID;

/**
 * Quita un material propio del repaso: pasa a «abandonado», sin fecha de repaso, y conserva su historial
 * (repasos y tests siguen contando para la racha y «Tu estudio»). Repasarlo de nuevo lo reactiva.
 */
public interface AbandonStudyMaterialUseCase {

    StudyMaterial abandonMaterial(UUID userId, UUID materialId);
}
