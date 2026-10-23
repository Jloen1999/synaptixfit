package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.model.academic.StudyDocument;
import com.synaptixfit.domain.model.academic.StudySourceType;
import java.util.UUID;

/** Genera con IA (o regenera, sobrescribiendo) el resumen, el mapa mental o el banco de práctica de una fuente. */
public interface GenerateStudyDocumentUseCase {

    StudyDocument generateDocument(UUID userId, StudySourceType sourceType, UUID sourceId, AiDocumentType type);
}
