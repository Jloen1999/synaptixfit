package com.synaptixfit.domain.model.catalog;

import java.util.UUID;

/** Centro (facultad o escuela) de una universidad. */
public record Center(UUID id, UUID universityId, String name) {
}
