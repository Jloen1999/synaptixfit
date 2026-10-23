package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.CommentView;
import java.time.Instant;
import java.util.UUID;

/** Comentario. {@code mine}: lo ha escrito el usuario actual (puede editarlo y borrarlo). */
public record CommentResponse(UUID id, UUID postId, AuthorResponse author, String text, Instant createdAt,
                              Instant editedAt, boolean edited, boolean mine) {

    public static CommentResponse from(CommentView c, UUID viewerId) {
        return new CommentResponse(c.id(), c.postId(), AuthorResponse.from(c.author()), c.text(), c.createdAt(),
                c.editedAt(), c.editedAt() != null, c.author().id().equals(viewerId));
    }
}
