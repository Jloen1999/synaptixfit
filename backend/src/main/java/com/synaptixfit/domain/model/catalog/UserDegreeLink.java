package com.synaptixfit.domain.model.catalog;

import java.time.Instant;
import java.util.UUID;

/** Vínculo entre el usuario y una carrera del catálogo. */
public record UserDegreeLink(UUID degreeId, Instant linkedAt) {
}
