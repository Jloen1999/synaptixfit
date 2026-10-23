package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;

/**
 * Parámetros planificados de un ejercicio. Rangos (los mismos que los CHECK de la base de datos):
 * series 1-10, repeticiones 1-100, descanso 30-300 s; peso 0-500 kg; duración 1-14400 s; distancia
 * 1-100000 m; isométrico 1-600 s; como mucho un peso por serie.
 */
public record ExerciseParameters(int sets, int reps, int restSeconds, Double weightKg, List<Double> weightsKg,
                                 Integer targetDurationSeconds, Integer distanceMeters, Integer isometricSeconds) {

    public static final int MIN_SETS = 1;
    public static final int MAX_SETS = 10;
    public static final int MIN_REPS = 1;
    public static final int MAX_REPS = 100;
    public static final int MIN_REST = 30;
    public static final int MAX_REST = 300;

    public ExerciseParameters {
        Guard.range(sets, "sets", MIN_SETS, MAX_SETS);
        Guard.range(reps, "reps", MIN_REPS, MAX_REPS);
        Guard.range(restSeconds, "restSeconds", MIN_REST, MAX_REST);
        if (weightKg != null) {
            Guard.range(weightKg, "weightKg", 0, 500);
        }
        weightsKg = weightsKg == null || weightsKg.isEmpty() ? null : List.copyOf(weightsKg);
        if (weightsKg != null) {
            if (weightsKg.size() > MAX_SETS) {
                throw new FieldValidationException("weightsKg", "OUT_OF_RANGE", "at most one weight per set");
            }
            weightsKg.forEach(w -> Guard.range(w, "weightsKg", 0, 500));
        }
        if (targetDurationSeconds != null) {
            Guard.range(targetDurationSeconds, "targetDurationSeconds", 1, 14_400);
        }
        if (distanceMeters != null) {
            Guard.range(distanceMeters, "distanceMeters", 1, 100_000);
        }
        if (isometricSeconds != null) {
            Guard.range(isometricSeconds, "isometricSeconds", 1, 600);
        }
    }

    /**
     * Construye parámetros a partir de valores calculados (reglas, IA, progresión) ajustándolos a los
     * rangos válidos en lugar de rechazarlos.
     */
    public static ExerciseParameters clamped(int sets, int reps, int restSeconds, Double weightKg,
                                             List<Double> weightsKg, Integer targetDurationSeconds,
                                             Integer distanceMeters, Integer isometricSeconds) {
        List<Double> weights = weightsKg == null ? null : weightsKg.stream()
                .limit(MAX_SETS).map(w -> roundWeight(clamp(w, 0, 500))).toList();
        return new ExerciseParameters(clamp(sets, MIN_SETS, MAX_SETS), clamp(reps, MIN_REPS, MAX_REPS),
                clamp(restSeconds, MIN_REST, MAX_REST),
                weightKg == null ? null : roundWeight(clamp(weightKg, 0, 500)), weights,
                targetDurationSeconds == null ? null : clamp(targetDurationSeconds, 1, 14_400),
                distanceMeters == null ? null : clamp(distanceMeters, 1, 100_000),
                isometricSeconds == null ? null : clamp(isometricSeconds, 1, 600));
    }

    public static int clamp(int v, int min, int max) {
        return Math.max(min, Math.min(max, v));
    }

    public static double clamp(double v, double min, double max) {
        return Math.max(min, Math.min(max, v));
    }

    /** Redondea pesos a 0,5 kg (incremento mínimo habitual de los discos). */
    public static double roundWeight(double kg) {
        return Math.round(kg * 2) / 2.0;
    }
}
