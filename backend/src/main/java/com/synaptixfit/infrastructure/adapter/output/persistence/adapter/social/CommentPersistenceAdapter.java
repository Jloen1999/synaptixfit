package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.model.social.Comment;
import com.synaptixfit.domain.port.output.social.CommentRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.CommentEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social.SocialPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.social.CommentJpaRepository;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/** Implementa {@link CommentRepositoryPort} con JPA (escrituras volcadas al momento). */
@Repository
public class CommentPersistenceAdapter implements CommentRepositoryPort {

    private final CommentJpaRepository repository;

    public CommentPersistenceAdapter(CommentJpaRepository repository) {
        this.repository = repository;
    }

    @Override
    public Optional<Comment> findById(UUID id) {
        return repository.findById(id).map(SocialPersistenceMapper::toDomain);
    }

    @Override
    public Comment save(Comment comment) {
        CommentEntity entity = repository.findById(comment.id()).orElseGet(CommentEntity::new);
        SocialPersistenceMapper.copyToEntity(comment, entity);
        return SocialPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }
}
