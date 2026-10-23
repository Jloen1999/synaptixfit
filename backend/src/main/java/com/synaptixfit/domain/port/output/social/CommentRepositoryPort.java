package com.synaptixfit.domain.port.output.social;

import com.synaptixfit.domain.model.social.Comment;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de comentarios. */
public interface CommentRepositoryPort {

    Optional<Comment> findById(UUID id);

    Comment save(Comment comment);
}
