package com.synaptixfit.infrastructure.adapter.input.rest.catalog.dto;

import com.synaptixfit.domain.model.catalog.CatalogSubject;
import java.util.UUID;

/** Asignatura del plan de estudios. {@code semester} 0 = sin semestre fijo. */
public record CatalogSubjectResponse(UUID id, UUID degreeId, String name, Integer course, Integer semester,
                                     String character, Double credits, Integer hours, String department,
                                     String language, String teachingGuideUrl) {

    public static CatalogSubjectResponse from(CatalogSubject s) {
        return new CatalogSubjectResponse(s.id(), s.degreeId(), s.name(), s.course(), s.semester(), s.character(),
                s.credits(), s.hours(), s.department(), s.language(), s.teachingGuideUrl());
    }
}
