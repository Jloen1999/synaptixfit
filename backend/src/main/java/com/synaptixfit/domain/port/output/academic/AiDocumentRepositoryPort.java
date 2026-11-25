package com.synaptixfit.domain.port.output.academic;

import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/** Persistencia de los documentos generados por la IA (único por usuario, fuente y tipo). */
public interface AiDocumentRepositoryPort {

    Optional<AiDocument> find(UUID userId, AiDocumentSource source, String sourceId, AiDocumentType type);

    /**
     * Los documentos de un tipo de varias fuentes a la vez (p. ej. el plan docente de cada asignatura de la lista),
     * por id de fuente. La versión por defecto los busca uno a uno; el adaptador lo hace con una consulta.
     */
    default Map<String, AiDocument> findAll(UUID userId, AiDocumentSource source, Collection<String> sourceIds,
                                            AiDocumentType type) {
        Map<String, AiDocument> found = new HashMap<>();
        for (String id : sourceIds) {
            find(userId, source, id, type).ifPresent(d -> found.put(id, d));
        }
        return found;
    }

    Set<AiDocumentType> typesFor(UUID userId, AiDocumentSource source, String sourceId);

    /**
     * Los tipos guardados de varias fuentes a la vez (la lista «Material», ADR 0064), por id de fuente; solo salen
     * las que tienen alguno. La versión por defecto pregunta una a una; el adaptador lo hace con una consulta.
     */
    default Map<String, Set<AiDocumentType>> typesForAll(UUID userId, AiDocumentSource source,
                                                         Collection<String> sourceIds) {
        Map<String, Set<AiDocumentType>> found = new HashMap<>();
        for (String id : sourceIds) {
            Set<AiDocumentType> types = typesFor(userId, source, id);
            if (!types.isEmpty()) {
                found.put(id, types);
            }
        }
        return found;
    }

    AiDocument save(AiDocument document);

    void delete(UUID id);

    void deleteBySource(UUID userId, AiDocumentSource source, String sourceId);
}
