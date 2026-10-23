package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.ReportedContent;
import com.synaptixfit.domain.model.social.ReportedContentType;
import java.time.Instant;
import java.util.UUID;

/** Contenido reportado. Para comentarios, {@code postId} es la publicación a la que pertenecen. */
public record ReportedContentResponse(ReportedContentType type, UUID id, UUID postId, UUID authorId,
                                      String authorName, String content, UUID reportedBy, Instant createdAt) {

    public static ReportedContentResponse from(ReportedContent r) {
        return new ReportedContentResponse(r.type(), r.id(), r.postId(), r.authorId(), r.authorName(), r.content(),
                r.reportedBy(), r.createdAt());
    }
}
