package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideImportView;
import java.util.UUID;

/** Estado y resultado de una importación de plan docente (el cliente lo consulta hasta que acaba). */
public interface GetTeachingGuideImportUseCase {

    TeachingGuideImportView getImport(UUID userId, UUID importId);
}
