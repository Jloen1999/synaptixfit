package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.profile;

import com.synaptixfit.domain.model.profile.AcademicProfile;
import com.synaptixfit.domain.port.output.profile.AcademicProfileRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.profile.AcademicProfileEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.profile.ProfilePersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.profile.AcademicProfileJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link AcademicProfileRepositoryPort} con JPA. */
@Repository
public class AcademicProfilePersistenceAdapter implements AcademicProfileRepositoryPort {

    private final AcademicProfileJpaRepository repository;

    public AcademicProfilePersistenceAdapter(AcademicProfileJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<AcademicProfile> findByUserId(UUID userId) {
        return repository.findByUsuarioId(userId).map(ProfilePersistenceMapper::toDomain);
    }

    @Override
    public AcademicProfile save(AcademicProfile profile) {
        AcademicProfileEntity entity = repository.findById(profile.id()).orElseGet(AcademicProfileEntity::new);
        ProfilePersistenceMapper.copyToEntity(profile, entity);
        return ProfilePersistenceMapper.toDomain(repository.save(entity));
    }
}
