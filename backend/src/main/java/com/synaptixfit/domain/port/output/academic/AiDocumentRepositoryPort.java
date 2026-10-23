package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Persistencia de los documentos generados por la IA (único por usuario, fuente y tipo). */
public interface AiDocumentRepositoryPort {

    Optional<AiDocument> find(UUID userId, AiDocumentSource source, String sourceId, AiDocumentType type);

    Set<AiDocumentType> typesFor(UUID userId, AiDocumentSource source, String sourceId);

    AiDocument save(AiDocument document);

    void delete(UUID id);

    void deleteBySource(UUID userId, AiDocumentSource source, String sourceId);
}
