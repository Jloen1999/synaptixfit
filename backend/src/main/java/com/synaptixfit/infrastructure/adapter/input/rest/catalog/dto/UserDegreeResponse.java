package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.UserDegree;
import java.time.Instant;

/** Carrera vinculada por el usuario. */
public record UserDegreeResponse(DegreeResponse degree, Instant linkedAt) {

    public static UserDegreeResponse from(UserDegree d) {
        return new UserDegreeResponse(DegreeResponse.from(d.degree()), d.linkedAt());
    }
}
