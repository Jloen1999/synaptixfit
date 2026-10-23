package com.synaptixfit.infrastructure.adapter.output.persistence.adapter;

import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.UserEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.UserPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.UserJpaRepository;
import java.time.Clock;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link UserRepositoryPort} con JPA. */
@Repository
public class UserPersistenceAdapter implements UserRepositoryPort {

    private final UserJpaRepository repository;
    private final Clock clock;

    public UserPersistenceAdapter(UserJpaRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    @Override
    public Optional<User> findById(UUID id) {
        return repository.findById(id).map(UserPersistenceMapper::toDomain);
    }

    @Override
    public Optional<User> findByEmail(String normalizedEmail) {
        return repository.findByEmail(normalizedEmail).map(UserPersistenceMapper::toDomain);
    }

    @Override
    public Optional<User> findByGoogleSubject(String subject) {
        return repository.findByGoogleSub(subject).map(UserPersistenceMapper::toDomain);
    }

    @Override
    public boolean existsByEmail(String normalizedEmail) {
        return repository.existsByEmail(normalizedEmail);
    }

    @Override
    public User save(User user) {
        UserEntity entity = repository.findById(user.id()).orElseGet(UserEntity::new);
        UserPersistenceMapper.copyToEntity(user, entity);
        entity.setActualizadoEn(clock.instant());
        return UserPersistenceMapper.toDomain(repository.save(entity));
    }
}
