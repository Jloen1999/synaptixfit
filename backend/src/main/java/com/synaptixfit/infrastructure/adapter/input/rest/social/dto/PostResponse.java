package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.PostType;
import java.time.Instant;
import java.util.UUID;

/** Publicación del muro. {@code mine}: la ha escrito el usuario actual (puede editarla y borrarla). */
public record PostResponse(UUID id, AuthorResponse author, PostType type, String description, String imageUrl,
                           Object metadata, Instant createdAt, Instant editedAt, boolean edited, long likesCount,
                           long commentsCount, boolean likedByMe, boolean mine) {
}
