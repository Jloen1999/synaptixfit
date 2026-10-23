package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights;

import com.synaptixfit.domain.model.insights.CognitiveState;
import com.synaptixfit.domain.port.output.insights.CognitiveStateRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.CognitiveStateEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.insights.InsightsPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.insights.CognitiveStateJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link CognitiveStateRepositoryPort} con JPA. */
@Repository
public class CognitiveStatePersistenceAdapter implements CognitiveStateRepositoryPort {

    private final CognitiveStateJpaRepository repository;

    public CognitiveStatePersistenceAdapter(CognitiveStateJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<CognitiveState> findByUser(UUID userId) {
        return repository.findById(userId).map(InsightsPersistenceMapper::toDomain);
    }

    @Override
    public CognitiveState save(CognitiveState state) {
        CognitiveStateEntity entity = repository.findById(state.userId()).orElseGet(CognitiveStateEntity::new);
        InsightsPersistenceMapper.copyToEntity(state, entity);
        repository.save(entity);
        return state;
    }
}
