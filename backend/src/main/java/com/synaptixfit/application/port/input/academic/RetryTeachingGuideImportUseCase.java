package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideImportView;
import java.util.UUID;

/** Vuelve a analizar una importación que falló (IA no disponible, cuota agotada…). */
public interface RetryTeachingGuideImportUseCase {

    TeachingGuideImportView retry(UUID userId, UUID importId);
}
