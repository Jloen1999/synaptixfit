package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.FriendshipEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social.SocialPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.social.FriendshipJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link FriendshipRepositoryPort} con JPA (escrituras volcadas al momento). */
@Repository
public class FriendshipPersistenceAdapter implements FriendshipRepositoryPort {

    private final FriendshipJpaRepository repository;

    public FriendshipPersistenceAdapter(FriendshipJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<Friendship> findById(UUID id) {
        return repository.findById(id).map(SocialPersistenceMapper::toDomain);
    }

    /** Si hay filas en ambos sentidos (datos heredados) se usa la más reciente. */
    @Override
    public Optional<Friendship> findBetween(UUID userA, UUID userB) {
        return repository.findBetween(userA, userB).stream().findFirst().map(SocialPersistenceMapper::toDomain);
    }

    @Override
    public Friendship save(Friendship friendship) {
        FriendshipEntity entity = repository.findById(friendship.id()).orElseGet(FriendshipEntity::new);
        SocialPersistenceMapper.copyToEntity(friendship, entity);
        return SocialPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
