package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social.SocialPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.social.PostJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link PostRepositoryPort} con JPA. Las escrituras se vuelcan al momento porque las
 * lecturas compuestas del módulo usan JDBC dentro de la misma transacción.
 */
@Repository
public class PostPersistenceAdapter implements PostRepositoryPort {

    private final PostJpaRepository repository;

    public PostPersistenceAdapter(PostJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<Post> findById(UUID id) {
        return repository.findById(id).map(SocialPersistenceMapper::toDomain);
    }

    @Override
    public Post save(Post post) {
        PostEntity entity = repository.findById(post.id()).orElseGet(PostEntity::new);
        SocialPersistenceMapper.copyToEntity(post, entity);
        return SocialPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public boolean existsByAuthorTypeAndMetadata(UUID userId, PostType type, String metadata) {
        return repository.existsByUsuarioIdAndTipoAndMetadata(userId, SocialPersistenceMapper.postTypeToDb(type),
                metadata);
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
