package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.Modality;
import com.synaptixfit.domain.model.training.TrainingGoal;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * Parámetros de entrenamiento por objetivo (tabla calibrada contra el dataset de ejercicios del
 * sistema heredado). Los valores por defecto de un ejercicio nuevo son el punto medio de cada rango.
 */
public record GoalParameters(TrainingGoal goal, int setsMin, int setsMax, int repsMin, int repsMax,
                             int restMin, int restMax, double rpeMin, double rpeMax, double relativeIntensity,
                             int exercisesPerDay, boolean prioritizeCompound, List<Modality> modalities,
                             int weeklyVolumeTarget, boolean allowsCircuit) {

    private static final Map<TrainingGoal, GoalParameters> TABLE = new EnumMap<>(TrainingGoal.class);

    static {
        put(new GoalParameters(TrainingGoal.HYPERTROPHY, 3, 4, 6, 15, 60, 120, 7.0, 9.0, 0.70, 5, true,
                List.of(Modality.STRENGTH), 15, false));
        put(new GoalParameters(TrainingGoal.MAX_STRENGTH, 3, 5, 1, 6, 120, 300, 8.0, 9.5, 0.85, 3, true,
                List.of(Modality.STRENGTH), 10, false));
        put(new GoalParameters(TrainingGoal.POWER, 3, 5, 1, 5, 120, 240, 7.0, 8.5, 0.75, 3, true,
                List.of(Modality.METABOLIC), 8, true));
        put(new GoalParameters(TrainingGoal.STRENGTH_ENDURANCE, 2, 3, 12, 25, 30, 60, 5.0, 7.0, 0.55, 6, false,
                List.of(Modality.STRENGTH), 12, false));
        put(new GoalParameters(TrainingGoal.MOBILITY, 2, 3, 8, 15, 30, 60, 3.0, 5.0, 0.30, 7, false,
                List.of(Modality.MOBILITY), 6, false));
        put(new GoalParameters(TrainingGoal.STABILITY, 2, 3, 6, 12, 45, 90, 4.0, 6.0, 0.40, 6, false,
                List.of(Modality.STRENGTH), 8, false));
        put(new GoalParameters(TrainingGoal.METABOLIC_CONDITIONING, 2, 3, 12, 25, 20, 45, 6.0, 8.0, 0.50, 5, true,
                List.of(Modality.AEROBIC), 10, true));
    }

    private static void put(GoalParameters p) {
        TABLE.put(p.goal(), p);
    }

    public static GoalParameters of(TrainingGoal goal) {
        return TABLE.get(goal == null ? TrainingGoal.HYPERTROPHY : goal);
    }

    public int defaultSets() {
        return (setsMin + setsMax) / 2;
    }

    public int defaultReps() {
        return (repsMin + repsMax) / 2;
    }

    public int defaultRest() {
        return (restMin + restMax) / 2;
    }

    public int clampSets(int v) {
        return Math.max(setsMin, Math.min(setsMax, v));
    }

    public int clampReps(int v) {
        return Math.max(repsMin, Math.min(repsMax, v));
    }

    public int clampRest(int v) {
        return Math.max(restMin, Math.min(restMax, v));
    }

    /** Copia con otra intensidad y otro rango de repeticiones (ajustes biométricos). */
    public GoalParameters withIntensityAndReps(double intensity, int newRepsMin, int newRepsMax) {
        return new GoalParameters(goal, setsMin, setsMax, newRepsMin, newRepsMax, restMin, restMax, rpeMin, rpeMax,
                intensity, exercisesPerDay, prioritizeCompound, modalities, weeklyVolumeTarget, allowsCircuit);
    }
}
