package com.synaptixfit.domain.model.social;

import java.time.Instant;
import java.util.UUID;

/** Comentario con los datos de su autor. */
public record CommentView(UUID id, UUID postId, AuthorSummary author, String text, Instant createdAt,
                          Instant editedAt) {
}
