package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.StudyDocument;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.util.UUID;

/** Devuelve el documento de IA guardado de una fuente (cargar sin regenerar). */
public interface GetStudyDocumentUseCase {

    StudyDocument getDocument(UUID userId, StudySourceType sourceType, UUID sourceId, AiDocumentType type);
}
