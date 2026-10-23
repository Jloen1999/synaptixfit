package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.util.Set;
import java.util.UUID;

/** Qué documentos de IA tiene guardados una fuente propia (para los iconos del cliente). */
public interface GetStudyDocumentAvailabilityUseCase {

    Set<AiDocumentType> availableDocuments(UUID userId, StudySourceType sourceType, UUID sourceId);
}
