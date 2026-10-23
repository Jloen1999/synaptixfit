package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.catalog;

import com.synaptixfit.domain.model.catalog.UserDegreeLink;
import com.synaptixfit.domain.port.output.catalog.UserDegreeRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.catalog.UserDegreeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.catalog.UserDegreeJpaRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link UserDegreeRepositoryPort} con JPA. */
@Repository
public class UserDegreePersistenceAdapter implements UserDegreeRepositoryPort {

    private final UserDegreeJpaRepository repository;

    public UserDegreePersistenceAdapter(UserDegreeJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public List<UserDegreeLink> findByUser(UUID userId) {
        return repository.findByUsuarioIdOrderByCreadoEnAsc(userId).stream()
                .map(e -> new UserDegreeLink(e.getCarreraId(), e.getCreadoEn()))
                .toList();
    }

    @Override
    public boolean exists(UUID userId, UUID degreeId) {
        return repository.existsByUsuarioIdAndCarreraId(userId, degreeId);
    }

    @Override
    public void link(UUID userId, UUID degreeId, Instant when) {
        UserDegreeEntity entity = new UserDegreeEntity();
        entity.setId(UUID.randomUUID());
        entity.setUsuarioId(userId);
        entity.setCarreraId(degreeId);
        entity.setCreadoEn(when);
        repository.save(entity);
    }

    @Override
    public void unlink(UUID userId, UUID degreeId) {
        repository.deleteLink(userId, degreeId);
    }
}
