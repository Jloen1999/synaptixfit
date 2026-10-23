package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.academic.StudySourceType;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.StudyMaterialEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicDbCodes;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.StudyMaterialJpaRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

/** Implementa {@link StudyMaterialRepositoryPort} con JPA. */
@Repository
public class StudyMaterialPersistenceAdapter implements StudyMaterialRepositoryPort {

    private final StudyMaterialJpaRepository repository;

    public StudyMaterialPersistenceAdapter(StudyMaterialJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<StudyMaterial> findByIdAndUser(UUID id, UUID userId) {
        return repository.findByIdAndUserId(id, userId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public Optional<StudyMaterial> findByOrigin(UUID userId, StudySourceType originType, UUID originId) {
        return repository.findByUserIdAndOriginTypeAndOriginId(userId, AcademicDbCodes.sourceType(originType), originId)
                .map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public List<StudyMaterial> findByUser(UUID userId, UUID subjectId) {
        List<StudyMaterialEntity> rows = subjectId == null ? repository.findByUserIdOrderByCreatedAtDesc(userId)
                : repository.findByUserIdAndSubjectIdOrderByCreatedAtDesc(userId, subjectId);
        return rows.stream().map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public List<StudyMaterial> findDue(UUID userId, Instant now, int limit) {
        return repository.findDue(userId, now, PageRequest.of(0, limit)).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public StudyMaterial save(StudyMaterial material) {
        StudyMaterialEntity entity = repository.findById(material.id()).orElseGet(StudyMaterialEntity::new);
        AcademicPersistenceMapper.copy(material, entity);
        return AcademicPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
