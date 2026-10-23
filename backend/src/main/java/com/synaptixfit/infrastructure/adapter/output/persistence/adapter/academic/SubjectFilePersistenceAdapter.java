package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.SubjectFile;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectFileEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.SubjectFileJpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link SubjectFileRepositoryPort} con JPA. */
@Repository
public class SubjectFilePersistenceAdapter implements SubjectFileRepositoryPort {

    private final SubjectFileJpaRepository repository;

    public SubjectFilePersistenceAdapter(SubjectFileJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<SubjectFile> findByIdAndUser(UUID id, UUID userId) {
        return repository.findByIdAndUserId(id, userId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public List<SubjectFile> findBySubject(UUID userId, UUID subjectId) {
        return repository.findByUserIdAndSubjectIdOrderByCreatedAtDesc(userId, subjectId).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public boolean existsByObjectKey(String objectKey) {
        return repository.existsByObjectKey(objectKey);
    }

    @Override
    public SubjectFile save(SubjectFile file) {
        SubjectFileEntity entity = repository.findById(file.id()).orElseGet(SubjectFileEntity::new);
        AcademicPersistenceMapper.copy(file, entity);
        return AcademicPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
