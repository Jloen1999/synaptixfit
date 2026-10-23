package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.TeachingGuideImport;
import com.synaptixfit.domain.model.academic.TeachingGuideImport.Status;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.academic.TeachingGuideImportRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.TeachingGuideImportEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.TeachingGuideImportJpaRepository;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link TeachingGuideImportRepositoryPort} con JPA. El resultado de la IA se guarda con
 * el mismo códec JSON que la guía de {@code documentos_ia}.
 */
@Repository
public class TeachingGuideImportPersistenceAdapter implements TeachingGuideImportRepositoryPort {

    private static final Map<Status, String> CODES = Map.of(Status.PENDING, "pendiente", Status.PROCESSING,
            "procesando", Status.READY, "lista", Status.FAILED, "fallida", Status.APPLIED, "aplicada");

    private final TeachingGuideImportJpaRepository repository;
    private final StudyDocumentCodecPort codec;

    public TeachingGuideImportPersistenceAdapter(TeachingGuideImportJpaRepository repository,
                                                 StudyDocumentCodecPort codec) {
        this.repository = repository;
        this.codec = codec;
    }

    @Override
    public Optional<TeachingGuideImport> findById(UUID id) {
        return repository.findById(id).map(this::toDomain);
    }

    @Override
    public Optional<TeachingGuideImport> findByIdAndUser(UUID id, UUID userId) {
        return repository.findByIdAndUserId(id, userId).map(this::toDomain);
    }

    @Override
    public TeachingGuideImport create(TeachingGuideImport i) {
        TeachingGuideImportEntity e = new TeachingGuideImportEntity();
        e.setId(i.id());
        e.setUserId(i.userId());
        e.setTargetSubjectId(i.targetSubjectId());
        e.setObjectKey(i.objectKey());
        e.setFileName(i.fileName());
        e.setMimeType(i.mimeType());
        e.setSizeBytes(i.sizeBytes());
        e.setStatus(CODES.get(i.status()));
        e.setResult(i.guide() == null ? null : codec.encodeTeachingGuide(i.guide()));
        e.setErrorCode(i.errorCode());
        e.setAppliedSubjectId(i.appliedSubjectId());
        e.setCreatedAt(i.createdAt());
        e.setUpdatedAt(i.updatedAt());
        return toDomain(repository.save(e));
    }

    @Override
    public boolean transition(Status expected, TeachingGuideImport i) {
        return repository.transition(i.id(), CODES.get(expected), CODES.get(i.status()),
                i.guide() == null ? null : codec.encodeTeachingGuide(i.guide()), i.errorCode(),
                i.appliedSubjectId(), i.updatedAt()) == 1;
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
    }

    private TeachingGuideImport toDomain(TeachingGuideImportEntity e) {
        Status status = CODES.entrySet().stream().filter(c -> c.getValue().equals(e.getStatus()))
                .map(Map.Entry::getKey).findFirst().orElse(Status.FAILED);
        return new TeachingGuideImport(e.getId(), e.getUserId(), e.getTargetSubjectId(), e.getObjectKey(),
                e.getFileName(), e.getMimeType(), e.getSizeBytes(), status,
                e.getResult() == null ? null : codec.decodeTeachingGuide(e.getResult()), e.getErrorCode(),
                e.getAppliedSubjectId(), e.getCreatedAt(), e.getUpdatedAt());
    }
}
