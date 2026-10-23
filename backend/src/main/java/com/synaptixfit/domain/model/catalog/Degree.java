package com.synaptixfit.domain.model.catalog;

import java.util.UUID;

/** Carrera (titulación) del catálogo con su contexto de centro y universidad. */
public record Degree(UUID id, String name, Integer totalCredits, Integer totalHours, UUID centerId, String centerName,
                     UUID universityId, String universityName) {
}
