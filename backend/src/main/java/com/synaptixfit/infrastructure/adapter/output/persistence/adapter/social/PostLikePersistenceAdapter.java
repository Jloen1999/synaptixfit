package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.port.output.social.PostLikeRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostLikeEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.social.PostLikeJpaRepository;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link PostLikeRepositoryPort} con JPA. */
@Repository
public class PostLikePersistenceAdapter implements PostLikeRepositoryPort {

    private final PostLikeJpaRepository repository;

    public PostLikePersistenceAdapter(PostLikeJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public boolean exists(UUID postId, UUID userId) {
        return repository.existsByActividadIdAndUsuarioId(postId, userId);
    }

    @Override
    public void add(UUID postId, UUID userId, Instant at) {
        PostLikeEntity entity = new PostLikeEntity();
        entity.setId(UUID.randomUUID());
        entity.setActividadId(postId);
        entity.setUsuarioId(userId);
        entity.setTipoInteraccion(PostLikeEntity.LIKE);
        entity.setCreadoEn(at);
        repository.saveAndFlush(entity);
    }

    @Override
    public void remove(UUID postId, UUID userId) {
        repository.deleteLike(postId, userId);
    }

    @Override
    public long countByPost(UUID postId) {
        return repository.countByActividadId(postId);
    }
}
