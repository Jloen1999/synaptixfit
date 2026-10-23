package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.Objects;
import java.util.UUID;

/** Serie realizada en una sesión. {@code plannedExerciseId} enlaza con el ejercicio planificado (si lo hay). */
public record SessionSet(UUID id, UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                         boolean completed, int failedReps) {

    public SessionSet {
        Objects.requireNonNull(id, "id");
        Guard.range(setNumber, "setNumber", 1, 50);
        if (repsDone != null) {
            Guard.range(repsDone, "repsDone", 0, 1000);
        }
        if (weightKg != null) {
            Guard.range(weightKg, "weightKg", 0, 500);
        }
        Guard.range(failedReps, "failedReps", 0, 1000);
    }
}
