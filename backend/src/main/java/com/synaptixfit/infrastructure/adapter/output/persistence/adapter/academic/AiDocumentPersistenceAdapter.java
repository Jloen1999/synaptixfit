package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.AiDocument;
import com.synaptixfit.domain.model.academic.AiDocumentSource;
import com.synaptixfit.domain.model.academic.AiDocumentType;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.AiDocumentEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicDbCodes;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.AiDocumentJpaRepository;
import java.util.Collection;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link AiDocumentRepositoryPort} con JPA. */
@Repository
public class AiDocumentPersistenceAdapter implements AiDocumentRepositoryPort {

    private final AiDocumentJpaRepository repository;

    public AiDocumentPersistenceAdapter(AiDocumentJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<AiDocument> find(UUID userId, AiDocumentSource source, String sourceId, AiDocumentType type) {
        return repository.findByUserIdAndSourceTypeAndSourceIdAndType(userId, AcademicDbCodes.documentSource(source),
                sourceId, AcademicDbCodes.documentType(type)).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public Map<String, AiDocument> findAll(UUID userId, AiDocumentSource source, Collection<String> sourceIds,
                                           AiDocumentType type) {
        Map<String, AiDocument> found = new HashMap<>();
        if (sourceIds.isEmpty()) {
            return found;
        }
        repository.findByUserIdAndSourceTypeAndTypeAndSourceIdIn(userId, AcademicDbCodes.documentSource(source),
                        AcademicDbCodes.documentType(type), sourceIds)
                .forEach(e -> found.put(e.getSourceId(), AcademicPersistenceMapper.toDomain(e)));
        return found;
    }

    @Override
    public Set<AiDocumentType> typesFor(UUID userId, AiDocumentSource source, String sourceId) {
        Set<AiDocumentType> types = EnumSet.noneOf(AiDocumentType.class);
        repository.findByUserIdAndSourceTypeAndSourceId(userId, AcademicDbCodes.documentSource(source), sourceId)
                .forEach(e -> types.add(AcademicDbCodes.documentType(e.getType())));
        return types;
    }

    @Override
    public Map<String, Set<AiDocumentType>> typesForAll(UUID userId, AiDocumentSource source,
                                                        Collection<String> sourceIds) {
        Map<String, Set<AiDocumentType>> found = new HashMap<>();
        if (sourceIds.isEmpty()) {
            return found;
        }
        // Solo la fuente y el tipo: el contenido (resúmenes, mapas) no hace falta para pintar iconos.
        repository.findTypesBySources(userId, AcademicDbCodes.documentSource(source), sourceIds)
                .forEach(row -> found.computeIfAbsent((String) row[0], k -> EnumSet.noneOf(AiDocumentType.class))
                        .add(AcademicDbCodes.documentType((String) row[1])));
        return found;
    }

    @Override
    public AiDocument save(AiDocument document) {
        AiDocumentEntity entity = repository.findById(document.id()).orElseGet(AiDocumentEntity::new);
        AcademicPersistenceMapper.copy(document, entity);
        return AcademicPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
    }

    @Override
    public void deleteBySource(UUID userId, AiDocumentSource source, String sourceId) {
        repository.deleteBySource(userId, AcademicDbCodes.documentSource(source), sourceId);
    }
}
