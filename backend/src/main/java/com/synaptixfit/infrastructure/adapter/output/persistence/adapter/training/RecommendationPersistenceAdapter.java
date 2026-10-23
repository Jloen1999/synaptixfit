package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.training.Recommendation;
import com.synaptixfit.domain.port.output.training.RecommendationRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.training.RecommendationEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.training.TrainingPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.training.RecommendationJpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Repository;

/** Implementa {@link RecommendationRepositoryPort} con JPA ({@code datos} como jsonb). */
@Repository
public class RecommendationPersistenceAdapter implements RecommendationRepositoryPort {

    private final RecommendationJpaRepository repository;

    public RecommendationPersistenceAdapter(RecommendationJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Recommendation save(Recommendation recommendation) {
        RecommendationEntity entity = repository.findById(recommendation.id()).orElseGet(RecommendationEntity::new);
        TrainingPersistenceMapper.copy(recommendation, entity);
        return TrainingPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public void saveAll(List<Recommendation> recommendations) {
        recommendations.forEach(this::save);
    }

    @Override
    public Optional<Recommendation> findById(UUID id) {
        return repository.findById(id).map(TrainingPersistenceMapper::toDomain);
    }

    @Override
    public PageResult<Recommendation> findByUser(UUID userId, Boolean applied, PageRequest page) {
        org.springframework.data.domain.PageRequest pageable =
                org.springframework.data.domain.PageRequest.of(page.page(), page.size());
        Page<RecommendationEntity> result = applied == null
                ? repository.findByUsuarioIdOrderByCreadoEnDesc(userId, pageable)
                : repository.findByUsuarioIdAndAplicadaOrderByCreadoEnDesc(userId, applied, pageable);
        return new PageResult<>(result.getContent().stream().map(TrainingPersistenceMapper::toDomain).toList(),
                page.page(), page.size(), result.getTotalElements());
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
