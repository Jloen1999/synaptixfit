package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Qué documentos de IA tiene guardados cada apunte y cada archivo de una asignatura, de una vez (ADR 0064): la lista
 * «Material» pinta sus iconos con una sola petición en vez de una por elemento.
 */
public interface GetSubjectDocumentAvailabilityUseCase {

    /** Documentos guardados de una fuente; solo salen las que tienen alguno. */
    record SourceDocuments(StudySourceType sourceType, UUID sourceId, Set<AiDocumentType> types) {
    }

    List<SourceDocuments> availableDocuments(UUID userId, UUID subjectId);
}
