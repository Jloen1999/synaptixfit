package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.AuthorSummary;
import java.util.UUID;

/** Autor de una publicación o comentario. */
public record AuthorResponse(UUID id, String fullName, String avatarUrl) {

    public static AuthorResponse from(AuthorSummary a) {
        return new AuthorResponse(a.id(), a.fullName(), a.avatarUrl());
    }
}
