package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.profile;

import com.synaptixfit.domain.model.profile.WellnessProfile;
import com.synaptixfit.domain.port.output.profile.WellnessProfileRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.WellnessProfileEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.profile.ProfilePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile.WellnessProfileJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link WellnessProfileRepositoryPort} con JPA. */
@Repository
public class WellnessProfilePersistenceAdapter implements WellnessProfileRepositoryPort {

    private final WellnessProfileJpaRepository repository;

    public WellnessProfilePersistenceAdapter(WellnessProfileJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<WellnessProfile> findByUserId(UUID userId) {
        return repository.findByUsuarioId(userId).map(ProfilePersistenceMapper::toDomain);
    }

    @Override
    public WellnessProfile save(WellnessProfile profile) {
        WellnessProfileEntity entity = repository.findById(profile.id()).orElseGet(WellnessProfileEntity::new);
        ProfilePersistenceMapper.copyToEntity(profile, entity);
        return ProfilePersistenceMapper.toDomain(repository.save(entity));
    }
}
