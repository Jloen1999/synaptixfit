package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.Degree;
import java.util.UUID;

/** Carrera del catálogo con su centro y universidad. */
public record DegreeResponse(UUID id, String name, Integer totalCredits, Integer totalHours, UUID centerId,
                             String centerName, UUID universityId, String universityName) {

    public static DegreeResponse from(Degree d) {
        return new DegreeResponse(d.id(), d.name(), d.totalCredits(), d.totalHours(), d.centerId(), d.centerName(),
                d.universityId(), d.universityName());
    }
}
