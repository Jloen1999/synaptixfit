package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.util.Objects;
import java.util.UUID;

/** Ejercicio seleccionado en un día de rutina, con su orden y parámetros. */
public final class PlannedExercise {

    private final UUID id;
    private final ExerciseRef exercise;
    private ExerciseParameters parameters;
    private int order;
    private Integer realDurationSeconds;

    public PlannedExercise(UUID id, ExerciseRef exercise, ExerciseParameters parameters, int order,
                           Integer realDurationSeconds) {
        this.id = Objects.requireNonNull(id, "id");
        this.exercise = Objects.requireNonNull(exercise, "exercise");
        this.parameters = Guard.notNull(parameters, "parameters");
        this.order = order;
        this.realDurationSeconds = realDurationSeconds;
    }

    public void changeParameters(ExerciseParameters newParameters) {
        this.parameters = Guard.notNull(newParameters, "parameters");
    }

    void changeOrder(int newOrder) {
        this.order = newOrder;
    }

    /** Guarda la última duración real registrada al finalizar una sesión. */
    public void recordRealDuration(int seconds) {
        if (seconds > 0) {
            this.realDurationSeconds = seconds;
        }
    }

    PlannedExercise copyWithNewId() {
        return new PlannedExercise(UUID.randomUUID(), exercise, parameters, order, null);
    }

    /**
     * Cómo se apunta este ejercicio planificado. Mandan primero sus datos (con duración o distancia es cardio;
     * con aguante, isométrico) y después el catálogo ({@link ExerciseRef#trackingKind()}): así una rutina
     * antigua se sigue viendo como se planificó.
     */
    public TrackingKind trackingKind() {
        if (parameters.targetDurationSeconds() != null || parameters.distanceMeters() != null) {
            return TrackingKind.CARDIO;
        }
        if (parameters.isometricSeconds() != null) {
            return TrackingKind.HOLD;
        }
        return exercise.trackingKind();
    }

    public UUID id() { return id; }
    public ExerciseRef exercise() { return exercise; }
    public UUID exerciseId() { return exercise.id(); }
    public ExerciseParameters parameters() { return parameters; }
    public int order() { return order; }
    public Integer realDurationSeconds() { return realDurationSeconds; }
}
