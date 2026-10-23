package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.Center;
import java.util.UUID;

/** Centro (facultad o escuela). */
public record CenterResponse(UUID id, UUID universityId, String name) {

    public static CenterResponse from(Center c) {
        return new CenterResponse(c.id(), c.universityId(), c.name());
    }
}
