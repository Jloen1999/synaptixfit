package com.synaptixfit.domain.model.social;

import java.time.Instant;
import java.util.UUID;

/** Contenido reportado pendiente de moderación. Para comentarios, {@code postId} es su publicación. */
public record ReportedContent(ReportedContentType type, UUID id, UUID postId, UUID authorId, String authorName,
                              String content, UUID reportedBy, Instant createdAt) {
}
