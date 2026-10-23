package com.synaptixfit.domain.model.social;

import java.time.Instant;
import java.util.UUID;

/** Publicación lista para el muro: autor, contadores y si quien mira ha dado «me gusta». */
public record PostView(UUID id, AuthorSummary author, PostType type, String description, String imageUrl,
                       String metadata, Instant createdAt, Instant editedAt, long likesCount, long commentsCount,
                       boolean likedByMe) {
}
