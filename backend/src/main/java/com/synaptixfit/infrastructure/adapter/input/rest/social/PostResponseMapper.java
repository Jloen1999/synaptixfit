package com.synaptixfit.infrastructure.adapter.input.rest.social;

import com.synaptixfit.domain.model.social.PostView;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.AuthorResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.social.dto.PostResponse;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;

/**
 * Traduce publicaciones a la API. {@code metadata} se guarda como texto JSON y se expone como
 * objeto JSON; si el texto heredado no es JSON válido, se devuelve {@code null}.
 */
@Component
public class PostResponseMapper {

    private final JsonMapper json;

    public PostResponseMapper(JsonMapper json) {
        this.json = json;
    }

    public PostResponse toResponse(PostView p, UUID viewerId) {
        return new PostResponse(p.id(), AuthorResponse.from(p.author()), p.type(), p.description(), p.imageUrl(),
                readMetadata(p.metadata()), p.createdAt(), p.editedAt(), p.editedAt() != null, p.likesCount(),
                p.commentsCount(), p.likedByMe(), p.author().id().equals(viewerId));
    }

    public String writeMetadata(Map<String, Object> metadata) {
        return metadata == null ? null : json.writeValueAsString(metadata);
    }

    private Object readMetadata(String metadata) {
        if (metadata == null || metadata.isBlank()) {
            return null;
        }
        try {
            return json.readValue(metadata, Object.class);
        } catch (JacksonException e) {
            return null;
        }
    }
}
