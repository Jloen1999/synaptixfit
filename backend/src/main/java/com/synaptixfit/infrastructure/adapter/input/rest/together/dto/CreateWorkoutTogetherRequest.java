package com.synaptixfit.infrastructure.adapter.input.rest.together.dto;

import com.synaptixfit.domain.model.together.WorkoutTogether;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;
import java.util.UUID;

/** Entrenar juntos hoy un día de la rutina propia ({@code dayId} nulo: el siguiente por hacer) con 1-4 amigos. */
public record CreateWorkoutTogetherRequest(@NotNull UUID routineId, UUID dayId,
                                           @NotEmpty @Size(max = WorkoutTogether.MAX_FRIENDS) Set<UUID> friendIds) {
}
