package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Ejercicio seleccionado en un día de rutina, con su orden, parámetros y las duraciones reales de las últimas
 * {@value #RECENT_DURATIONS} veces que se entrenó (de las que aprende {@link SessionDurationEstimate}, ADR 0048).
 */
public final class PlannedExercise {

    /** Con tres datos la mediana ya descarta un día raro; más memoria no mejora la estimación de forma visible. */
    public static final int RECENT_DURATIONS = 3;

    private final UUID id;
    private final ExerciseRef exercise;
    private ExerciseParameters parameters;
    private int order;
    /** De la más antigua a la más reciente; como mucho {@link #RECENT_DURATIONS}. */
    private final List<RecordedDuration> recentDurations;

    /** @param recentDurations duraciones reales registradas (en cualquier orden; se quedan las más recientes) */
    public PlannedExercise(UUID id, ExerciseRef exercise, ExerciseParameters parameters, int order,
                           List<RecordedDuration> recentDurations) {
        this.id = Guard.notNull(id, "id");
        this.exercise = Guard.notNull(exercise, "exercise");
        this.parameters = Guard.notNull(parameters, "parameters");
        this.order = order;
        this.recentDurations = new ArrayList<>(recentDurations == null ? List.of() : recentDurations);
        this.recentDurations.sort(Comparator.comparing(RecordedDuration::recordedAt));
        trimDurations();
    }

    public void changeParameters(ExerciseParameters newParameters) {
        this.parameters = Guard.notNull(newParameters, "parameters");
    }

    void changeOrder(int newOrder) {
        this.order = newOrder;
    }

    /**
     * Guarda la duración real de una sesión terminada en {@code at}. Solo se recuerdan las
     * {@value #RECENT_DURATIONS} más recientes: la más vieja sale.
     */
    public void recordRealDuration(int seconds, Instant at) {
        if (seconds > 0) {
            recentDurations.add(new RecordedDuration(seconds, Guard.notNull(at, "at")));
            recentDurations.sort(Comparator.comparing(RecordedDuration::recordedAt));
            trimDurations();
        }
    }

    private void trimDurations() {
        while (recentDurations.size() > RECENT_DURATIONS) {
            recentDurations.removeFirst();
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

    /**
     * Repeticiones que faltaron en la serie {@code setNumber}: objetivo − hechas (nunca negativo). Solo hay
     * objetivo en las series previstas de un ejercicio de repeticiones; una serie extra, de aguante o de cardio
     * no tiene y da 0. Así la persona no tiene que contarlas: se deduce de lo que apunta.
     */
    public int missedReps(int setNumber, Integer repsDone) {
        if (repsDone == null || setNumber < 1 || setNumber > parameters.sets()
                || trackingKind() != TrackingKind.REPETITIONS) {
            return 0;
        }
        return Math.max(0, parameters.repsForSet(setNumber) - repsDone);
    }

    public UUID id() { return id; }
    public ExerciseRef exercise() { return exercise; }
    public UUID exerciseId() { return exercise.id(); }
    public ExerciseParameters parameters() { return parameters; }
    public int order() { return order; }
    /** Duraciones reales recordadas, de la más antigua a la más reciente. */
    public List<RecordedDuration> recentDurations() { return List.copyOf(recentDurations); }

    /**
     * Duración de referencia que usa la estimación (acotada y con la mediana de las últimas veces); nula si aún no
     * se ha entrenado.
     */
    public Integer realDurationSeconds() {
        return SessionDurationEstimate.learnedSeconds(parameters, recentSeconds());
    }

    private List<Integer> recentSeconds() {
        return recentDurations.stream().map(RecordedDuration::seconds).toList();
    }

    /** Duración prevista ({@link SessionDurationEstimate}). */
    public int estimatedSeconds() { return SessionDurationEstimate.exerciseSeconds(parameters, recentSeconds()); }
}
