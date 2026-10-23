package com.synaptixfit.domain.model.training;

import java.util.UUID;

/** Procedencia de una rutina clonada desde la comunidad. */
public record RoutineOrigin(UUID routineId, UUID ownerId, String ownerName) {
}
