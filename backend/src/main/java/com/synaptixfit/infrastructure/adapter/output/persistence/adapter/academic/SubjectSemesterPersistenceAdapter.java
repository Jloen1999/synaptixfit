package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.SubjectSemester;
import com.synaptixfit.domain.port.output.academic.SubjectSemesterRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.academic.SubjectSemesterEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.SubjectSemesterJpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link SubjectSemesterRepositoryPort} con JPA. */
@Repository
public class SubjectSemesterPersistenceAdapter implements SubjectSemesterRepositoryPort {

    private final SubjectSemesterJpaRepository repository;

    public SubjectSemesterPersistenceAdapter(SubjectSemesterJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<SubjectSemester> findByUser(UUID userId) {
        return repository.findByUserIdOrderByCourseAscSemesterAsc(userId).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }

    @Override
    public Optional<SubjectSemester> findBySubject(UUID userId, UUID subjectId) {
        return repository.findByUserIdAndSubjectId(userId, subjectId).map(AcademicPersistenceMapper::toDomain);
    }

    @Override
    public SubjectSemester save(SubjectSemester assignment) {
        SubjectSemesterEntity entity = repository.findById(assignment.id()).orElseGet(SubjectSemesterEntity::new);
        AcademicPersistenceMapper.copy(assignment, entity);
        return AcademicPersistenceMapper.toDomain(repository.save(entity));
    }

    @Override
    public void deleteBySubject(UUID userId, UUID subjectId) {
        repository.deleteByUserAndSubject(userId, subjectId);
    }
}
