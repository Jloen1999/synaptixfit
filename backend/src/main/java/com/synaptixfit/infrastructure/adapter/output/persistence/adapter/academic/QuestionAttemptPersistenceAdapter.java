package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.QuestionAttempt;
import com.synaptixfit.domain.port.output.academic.QuestionAttemptRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.academic.AcademicPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.academic.QuestionAttemptJpaRepository;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link QuestionAttemptRepositoryPort} con JPA. */
@Repository
public class QuestionAttemptPersistenceAdapter implements QuestionAttemptRepositoryPort {

    private final QuestionAttemptJpaRepository repository;

    public QuestionAttemptPersistenceAdapter(QuestionAttemptJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public QuestionAttempt save(QuestionAttempt attempt) {
        return AcademicPersistenceMapper.toDomain(repository.save(AcademicPersistenceMapper.toEntity(attempt)));
    }

    @Override
    public List<QuestionAttempt> findByUserAndQuestions(UUID userId, Collection<UUID> questionIds) {
        if (questionIds.isEmpty()) {
            return List.of();
        }
        return repository.findByUserIdAndQuestionIdIn(userId, questionIds).stream()
                .map(AcademicPersistenceMapper::toDomain).toList();
    }
}
