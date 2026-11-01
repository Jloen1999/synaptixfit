package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import java.util.List;
import java.util.function.Function;

/**
 * Parámetros planificados de un ejercicio. Rangos (los mismos que los CHECK de la base de datos):
 * series 1-10, repeticiones 1-100, descanso 30-300 s; peso 0-500 kg; duración 1-14400 s; distancia
 * 1-100000 m; isométrico 1-600 s; como mucho un valor por serie en cada lista.
 *
 * <p>Valores por serie (ADR 0027): {@code weightsKg}, {@code repsPerSet} e {@code isometricSecondsPerSet}
 * detallan la serie n en la posición n-1. Si una lista falta o es más corta, esa serie usa el valor común
 * ({@code weightKg}, {@code reps}, {@code isometricSeconds}); así las rutinas antiguas siguen igual.
 *
 * <p>El valor común es la referencia de lo que no va serie a serie (calorías, progresión) y lo fija esta
 * regla, no quien envía los datos: si una lista cubre todas las series, el común es la media de las
 * repeticiones, el peso de trabajo (el mayor, como en las series de aproximación) y el aguante más largo; si
 * todas coinciden, la lista sobra y se quita. Las listas más largas que las series se recortan.
 */
public record ExerciseParameters(int sets, int reps, int restSeconds, Double weightKg, List<Double> weightsKg,
                                 Integer targetDurationSeconds, Integer distanceMeters, Integer isometricSeconds,
                                 List<Integer> repsPerSet, List<Integer> isometricSecondsPerSet) {

    public static final int MIN_SETS = 1;
    public static final int MAX_SETS = 10;
    public static final int MIN_REPS = 1;
    public static final int MAX_REPS = 100;
    public static final int MIN_REST = 30;
    public static final int MAX_REST = 300;
    public static final int MAX_ISOMETRIC = 600;

    public ExerciseParameters {
        Guard.range(sets, "sets", MIN_SETS, MAX_SETS);
        Guard.range(reps, "reps", MIN_REPS, MAX_REPS);
        Guard.range(restSeconds, "restSeconds", MIN_REST, MAX_REST);
        if (weightKg != null) {
            Guard.range(weightKg, "weightKg", 0, 500);
        }
        weightsKg = perSet(weightsKg, "weightsKg");
        if (weightsKg != null) {
            weightsKg.forEach(w -> Guard.range(w, "weightsKg", 0, 500));
        }
        repsPerSet = perSet(repsPerSet, "repsPerSet");
        if (repsPerSet != null) {
            repsPerSet.forEach(r -> Guard.range(r, "repsPerSet", MIN_REPS, MAX_REPS));
        }
        isometricSecondsPerSet = perSet(isometricSecondsPerSet, "isometricSecondsPerSet");
        if (isometricSecondsPerSet != null) {
            isometricSecondsPerSet.forEach(s -> Guard.range(s, "isometricSecondsPerSet", 1, MAX_ISOMETRIC));
        }
        if (targetDurationSeconds != null) {
            Guard.range(targetDurationSeconds, "targetDurationSeconds", 1, 14_400);
        }
        if (distanceMeters != null) {
            Guard.range(distanceMeters, "distanceMeters", 1, 100_000);
        }
        if (isometricSeconds != null) {
            Guard.range(isometricSeconds, "isometricSeconds", 1, MAX_ISOMETRIC);
        }
        weightsKg = fit(weightsKg, sets);
        repsPerSet = fit(repsPerSet, sets);
        isometricSecondsPerSet = fit(isometricSecondsPerSet, sets);
        if (covers(repsPerSet, sets)) {
            reps = (int) Math.round(repsPerSet.stream().mapToInt(Integer::intValue).average().orElse(reps));
            repsPerSet = uniform(repsPerSet) ? null : repsPerSet;
        }
        if (covers(weightsKg, sets)) {
            weightKg = weightsKg.stream().mapToDouble(Double::doubleValue).max().orElse(0);
            weightsKg = uniform(weightsKg) ? null : weightsKg;
        }
        if (covers(isometricSecondsPerSet, sets)) {
            isometricSeconds = isometricSecondsPerSet.stream().mapToInt(Integer::intValue).max().orElse(1);
            isometricSecondsPerSet = uniform(isometricSecondsPerSet) ? null : isometricSecondsPerSet;
        }
    }

    private static <T> List<T> fit(List<T> values, int sets) {
        return values != null && values.size() > sets ? List.copyOf(values.subList(0, sets)) : values;
    }

    private static boolean covers(List<?> values, int sets) {
        return values != null && values.size() == sets;
    }

    private static boolean uniform(List<?> values) {
        return values.stream().distinct().count() <= 1;
    }

    /** Parámetros sin repeticiones ni tiempos por serie (forma anterior a ADR 0027). */
    public ExerciseParameters(int sets, int reps, int restSeconds, Double weightKg, List<Double> weightsKg,
                              Integer targetDurationSeconds, Integer distanceMeters, Integer isometricSeconds) {
        this(sets, reps, restSeconds, weightKg, weightsKg, targetDurationSeconds, distanceMeters, isometricSeconds,
                null, null);
    }

    private static <T> List<T> perSet(List<T> values, String field) {
        if (values == null || values.isEmpty()) {
            return null;
        }
        if (values.size() > MAX_SETS) {
            throw new FieldValidationException(field, "OUT_OF_RANGE", "at most one value per set");
        }
        if (values.stream().anyMatch(java.util.Objects::isNull)) {
            throw new FieldValidationException(field, "REQUIRED", "per-set values cannot be empty");
        }
        return List.copyOf(values);
    }

    /** Repeticiones previstas de la serie {@code setNumber} (desde 1). */
    public int repsForSet(int setNumber) {
        return valueForSet(repsPerSet, setNumber, reps);
    }

    /** Peso previsto de la serie {@code setNumber} (nulo si el ejercicio no lleva carga). */
    public Double weightForSet(int setNumber) {
        return valueForSet(weightsKg, setNumber, weightKg);
    }

    /** Segundos de aguante previstos de la serie {@code setNumber} (nulo si no es isométrico). */
    public Integer isometricSecondsForSet(int setNumber) {
        return valueForSet(isometricSecondsPerSet, setNumber, isometricSeconds);
    }

    private static <T> T valueForSet(List<T> values, int setNumber, T common) {
        return values != null && setNumber >= 1 && setNumber <= values.size() ? values.get(setNumber - 1) : common;
    }

    /**
     * Construye parámetros a partir de valores calculados (reglas, IA, progresión) ajustándolos a los
     * rangos válidos en lugar de rechazarlos.
     */
    public static ExerciseParameters clamped(int sets, int reps, int restSeconds, Double weightKg,
                                             List<Double> weightsKg, Integer targetDurationSeconds,
                                             Integer distanceMeters, Integer isometricSeconds) {
        return clamped(sets, reps, restSeconds, weightKg, weightsKg, targetDurationSeconds, distanceMeters,
                isometricSeconds, null, null);
    }

    /** Como {@link #clamped(int, int, int, Double, List, Integer, Integer, Integer)}, con valores por serie. */
    public static ExerciseParameters clamped(int sets, int reps, int restSeconds, Double weightKg,
                                             List<Double> weightsKg, Integer targetDurationSeconds,
                                             Integer distanceMeters, Integer isometricSeconds,
                                             List<Integer> repsPerSet, List<Integer> isometricSecondsPerSet) {
        List<Double> weights = clampList(weightsKg, w -> roundWeight(clamp(w, 0, 500)));
        return new ExerciseParameters(clamp(sets, MIN_SETS, MAX_SETS), clamp(reps, MIN_REPS, MAX_REPS),
                clamp(restSeconds, MIN_REST, MAX_REST),
                weightKg == null ? null : roundWeight(clamp(weightKg, 0, 500)), weights,
                targetDurationSeconds == null ? null : clamp(targetDurationSeconds, 1, 14_400),
                distanceMeters == null ? null : clamp(distanceMeters, 1, 100_000),
                isometricSeconds == null ? null : clamp(isometricSeconds, 1, MAX_ISOMETRIC),
                clampList(repsPerSet, r -> clamp(r, MIN_REPS, MAX_REPS)),
                clampList(isometricSecondsPerSet, s -> clamp(s, 1, MAX_ISOMETRIC)));
    }

    private static <T> List<T> clampList(List<T> values, Function<T, T> clamp) {
        return values == null ? null : values.stream()
                .filter(java.util.Objects::nonNull).limit(MAX_SETS).map(clamp).toList();
    }

    /** Aguante por defecto de un isométrico nuevo y bloque por defecto de un cardio nuevo. */
    public static final int DEFAULT_HOLD_SECONDS = 30;
    public static final int DEFAULT_CARDIO_SECONDS = 600;

    /**
     * Los mismos parámetros adaptados a otro ejercicio (al sustituirlo), según cómo se apunta el nuevo
     * ({@link ExerciseRef#trackingKind()}): se conservan series y descanso; repeticiones y carga solo en uno de
     * repeticiones (la carga, si se mide por peso); aguante en un isométrico; tiempo y distancia en un cardio.
     * Lo que falte toma el valor por defecto (30 s de aguante, 10 min de cardio).
     */
    public ExerciseParameters adaptedTo(ExerciseRef exercise) {
        boolean loaded = exercise.measuredBy(MeasurementType.WEIGHT);
        return switch (exercise.trackingKind()) {
            case REPETITIONS -> new ExerciseParameters(sets, reps, restSeconds, loaded ? weightKg : null,
                    loaded ? weightsKg : null, null, null, null, repsPerSet, null);
            case HOLD -> new ExerciseParameters(sets, reps, restSeconds, loaded ? weightKg : null,
                    loaded ? weightsKg : null, null, null,
                    isometricSeconds == null ? DEFAULT_HOLD_SECONDS : isometricSeconds, null, isometricSecondsPerSet);
            case CARDIO -> new ExerciseParameters(sets, reps, restSeconds, null, null,
                    targetDurationSeconds == null ? DEFAULT_CARDIO_SECONDS : targetDurationSeconds,
                    exercise.measuredBy(MeasurementType.DISTANCE) ? distanceMeters : null, null, null, null);
        };
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
