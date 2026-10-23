package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.profile;

import com.synaptixfit.domain.model.profile.WeightRecord;
import com.synaptixfit.domain.port.output.profile.WeightHistoryRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.profile.ProfilePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile.WeightHistoryJpaRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link WeightHistoryRepositoryPort} con JPA. */
@Repository
public class WeightHistoryPersistenceAdapter implements WeightHistoryRepositoryPort {

    private final WeightHistoryJpaRepository repository;

    public WeightHistoryPersistenceAdapter(WeightHistoryJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public WeightRecord append(WeightRecord record) {
        return ProfilePersistenceMapper.toDomain(repository.save(ProfilePersistenceMapper.toEntity(record)));
    }

    @Override
    public List<WeightRecord> findByUser(UUID userId, Instant fromInclusive, Instant toExclusive) {
        return repository
                .findByUsuarioIdAndRegistradoEnGreaterThanEqualAndRegistradoEnLessThanOrderByRegistradoEnAsc(
                        userId, fromInclusive, toExclusive)
                .stream().map(ProfilePersistenceMapper::toDomain).toList();
    }
}
