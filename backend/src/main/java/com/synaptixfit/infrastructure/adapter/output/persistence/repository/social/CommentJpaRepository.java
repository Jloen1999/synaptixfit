package com.synaptixfit.infrastructure.adapter.output.persistence.repository.social;

import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.CommentEntity;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Spring Data para {@code comentarios_feed}. */
public interface CommentJpaRepository extends JpaRepository<CommentEntity, UUID> {
}
