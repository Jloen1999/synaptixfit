package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.insights;

import com.synaptixfit.domain.model.insights.CrossRegulationState;
import com.synaptixfit.domain.port.output.insights.CrossRegulationRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.insights.CrossRegulationEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.insights.InsightsPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.insights.CrossRegulationJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link CrossRegulationRepositoryPort} con JPA. */
@Repository
public class CrossRegulationPersistenceAdapter implements CrossRegulationRepositoryPort {

    private final CrossRegulationJpaRepository repository;

    public CrossRegulationPersistenceAdapter(CrossRegulationJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<CrossRegulationState> findByUser(UUID userId) {
        return repository.findById(userId).map(InsightsPersistenceMapper::toDomain);
    }

    @Override
    public CrossRegulationState save(CrossRegulationState state) {
        CrossRegulationEntity entity = repository.findById(state.userId()).orElseGet(CrossRegulationEntity::new);
        InsightsPersistenceMapper.copyToEntity(state, entity);
        repository.save(entity);
        return state;
    }
}
