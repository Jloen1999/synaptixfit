package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.Objects;
import java.util.UUID;

/**
 * Serie realizada en una sesión. {@code plannedExerciseId} enlaza con el hueco de la rutina (si lo hay) y
 * {@code exerciseId} con el ejercicio que se hizo: si después se quita o se sustituye el hueco, la serie sigue
 * sabiendo qué ejercicio fue. Lo que se apunta depende de cómo se mide: repeticiones y peso, segundos de
 * aguante o de trabajo ({@code durationSeconds}) y metros ({@code distanceMeters}). {@code activeSeconds} es lo que
 * marcó el cronómetro de la serie sin sus pausas (ADR 0030); es opcional: se puede marcar una serie sin usarlo.
 */
public record SessionSet(UUID id, UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                         boolean completed, int failedReps, Integer durationSeconds, Integer distanceMeters,
                         UUID exerciseId, Integer activeSeconds) {

    public static final int MAX_DURATION_SECONDS = 14_400;
    public static final int MAX_DISTANCE_METERS = 100_000;

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
        if (durationSeconds != null) {
            Guard.range(durationSeconds, "durationSeconds", 0, MAX_DURATION_SECONDS);
        }
        if (distanceMeters != null) {
            Guard.range(distanceMeters, "distanceMeters", 0, MAX_DISTANCE_METERS);
        }
        if (activeSeconds != null) {
            Guard.range(activeSeconds, "activeSeconds", 0, MAX_DURATION_SECONDS);
        }
    }

    /** Serie sin el tiempo de su cronómetro. */
    public SessionSet(UUID id, UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                      boolean completed, int failedReps, Integer durationSeconds, Integer distanceMeters,
                      UUID exerciseId) {
        this(id, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps, durationSeconds,
                distanceMeters, exerciseId, null);
    }

    /** Serie de repeticiones y peso (sin tiempo ni distancia). */
    public SessionSet(UUID id, UUID plannedExerciseId, int setNumber, Integer repsDone, Double weightKg,
                      boolean completed, int failedReps) {
        this(id, plannedExerciseId, setNumber, repsDone, weightKg, completed, failedReps, null, null, null, null);
    }
}
