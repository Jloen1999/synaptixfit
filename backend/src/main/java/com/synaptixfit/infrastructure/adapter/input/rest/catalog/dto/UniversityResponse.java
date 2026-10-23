package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.University;
import java.util.UUID;

/** Universidad del catálogo; {@code type} y {@code region} pueden faltar en las que no son del RUCT. */
public record UniversityResponse(UUID id, String name, String type, String region) {

    public static UniversityResponse from(University u) {
        return new UniversityResponse(u.id(), u.name(), u.type(), u.region());
    }
}
