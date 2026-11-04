package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.SessionSet;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Sobrecarga progresiva (doble progresión) y degradación por inactividad, también para ejercicios
 * por tiempo, distancia e isométricos.
 *
 * <p>Tras una sesión: con repeticiones fallidas la carga baja {@code 5 %} por fallo (entre 5 % y
 * 30 %) y se quita una serie; RPE ≥ 9,5 → carga −15 %; RPE ≤ 5 → carga +10 % (isométrico +10 s);
 * RPE ≤ 7 → +1 repetición o, en el tope del rango, +5 % de peso y vuelta al mínimo de
 * repeticiones (tiempo/distancia +10 %). Con más de 14 días sin entrenar la carga baja al 80 %
 * (70 % a partir de 21 días), se quita una serie y se añaden 30 s de descanso.
 */
public final class ProgressionCalculator {

    public static final int INACTIVITY_DAYS = 14;

    private ProgressionCalculator() {
    }

    /**
     * Resultado: parámetros nuevos, explicación técnica y motivo. Ambos son nulos si no cambia nada o
     * si solo se ajustan al rango del objetivo (series, repeticiones o descanso fuera de rango).
     */
    public record Result(ExerciseParameters parameters, String log, AdjustmentReason reason) {
        public boolean changed(ExerciseParameters before) {
            return !parameters.equals(before);
        }
    }

    /** 1RM estimado con la fórmula no lineal heredada. */
    public static double oneRepMax(double weightKg, int reps) {
        if (reps <= 0 || weightKg <= 0) {
            return 0;
        }
        if (reps == 1) {
            return weightKg;
        }
        if (weightKg < 3.0) {
            return weightKg * (1 + 0.0333 * reps);
        }
        return weightKg * (1 + Math.pow(reps - 1, 0.85) / (-2.55 + 4.58 * Math.log(weightKg)));
    }

    /** Rampa de calentamiento: con 3+ series la primera al 50 % y la segunda al 75 %. */
    public static List<Double> warmupWeights(double targetKg, int totalSets) {
        List<Double> weights = new ArrayList<>();
        if (totalSets <= 1) {
            weights.add(targetKg);
            return weights;
        }
        for (int i = 1; i <= totalSets; i++) {
            if (i == 1 && totalSets >= 3) {
                weights.add(targetKg * 0.50);
            } else if (i == 2 && totalSets >= 3) {
                weights.add(targetKg * 0.75);
            } else {
                weights.add(targetKg);
            }
        }
        return weights;
    }

    public static Result progress(ExerciseParameters current, Collection<MeasurementType> types, double lastRpe,
                                  List<SessionSet> performedSets, GoalParameters goal) {
        boolean usesWeight = types.contains(MeasurementType.WEIGHT);
        boolean usesReps = types.contains(MeasurementType.REPETITIONS);
        boolean usesTime = types.contains(MeasurementType.TIME);
        boolean usesDistance = types.contains(MeasurementType.DISTANCE);
        boolean isometric = usesTime && !usesReps && current.isometricSeconds() != null;

        Double weight = current.weightKg();
        int sets = current.sets();
        int reps = current.reps();
        Integer duration = current.targetDurationSeconds();
        Integer distance = current.distanceMeters();
        Integer iso = current.isometricSeconds();
        String log = null;
        AdjustmentReason reason = null;

        int failed = performedSets == null ? 0 : performedSets.stream().mapToInt(SessionSet::failedReps).sum();
        if (failed > 0) {
            double factor = Math.max(70, Math.min(95, 100 - failed * 5)) / 100.0;
            weight = scale(weight, usesWeight, factor);
            duration = scale(duration, usesTime, factor);
            distance = scale(distance, usesDistance, factor);
            iso = scale(iso, isometric, factor);
            if (goal != null) {
                sets = goal.clampSets(sets - 1);
            }
            log = "-" + failed + " fallos → carga ×" + String.format(java.util.Locale.ROOT, "%.2f", factor);
            reason = AdjustmentReason.FAILED_REPS;
        } else if (lastRpe >= 9.5) {
            weight = scale(weight, usesWeight, 0.85);
            duration = scale(duration, usesTime, 0.85);
            distance = scale(distance, usesDistance, 0.85);
            iso = scale(iso, isometric, 0.85);
            log = "RPE muy alto → carga -15%";
            reason = AdjustmentReason.VERY_HIGH_RPE;
        } else if (performedSets != null && performedSets.stream().anyMatch(SessionSet::toFailure)) {
            // ADR 0031: alguna serie fue «hasta no poder más». Aunque el RPE de la sesión fuera bajo, ese
            // ejercicio ya llegó al límite: se repite la carga en vez de subirla.
            log = "Serie hasta no poder más → se mantiene la carga";
        } else if (lastRpe <= 5.0) {
            weight = scale(weight, usesWeight, 1.10);
            duration = scale(duration, usesTime, 1.10);
            distance = scale(distance, usesDistance, 1.10);
            if (isometric && iso != null) {
                iso = Math.max(5, Math.min(300, iso + 10));
            }
            log = "RPE muy bajo → carga +10%";
            reason = AdjustmentReason.VERY_LOW_RPE;
        } else if (lastRpe <= 7.0) {
            if (usesWeight && usesReps && weight != null) {
                int repsMax = goal == null ? 15 : goal.repsMax();
                if (current.reps() >= repsMax) {
                    weight = weight * 1.05;
                    reps = goal == null ? 6 : goal.repsMin();
                    log = "RPE bajo → +5% peso y repeticiones al mínimo";
                    reason = AdjustmentReason.LOW_RPE_MORE_WEIGHT;
                } else {
                    reps = current.reps() + 1;
                    log = "RPE bajo → +1 repetición";
                    reason = AdjustmentReason.LOW_RPE_MORE_REPS;
                }
            } else if (usesTime && duration != null) {
                duration = (int) Math.round(duration * 1.10);
                log = "RPE bajo → tiempo +10%";
                reason = AdjustmentReason.LOW_RPE_MORE_TIME;
            } else if (usesDistance && distance != null) {
                distance = (int) Math.round(distance * 1.10);
                log = "RPE bajo → distancia +10%";
                reason = AdjustmentReason.LOW_RPE_MORE_DISTANCE;
            }
        }

        int rest = current.restSeconds();
        if (goal != null) {
            sets = goal.clampSets(sets);
            reps = goal.clampReps(reps);
            rest = goal.clampRest(rest);
        }
        return new Result(build(current, sets, reps, rest, weight, usesWeight, duration, distance, iso), log,
                reason);
    }

    public static Result degradeForInactivity(ExerciseParameters current, Collection<MeasurementType> types,
                                              int daysInactive, GoalParameters goal) {
        if (daysInactive <= INACTIVITY_DAYS) {
            return new Result(current, null, null);
        }
        double factor = daysInactive > 21 ? 0.70 : 0.80;
        boolean usesWeight = types.contains(MeasurementType.WEIGHT);
        boolean isometric = types.contains(MeasurementType.TIME) && !types.contains(MeasurementType.REPETITIONS);
        Double weight = scale(current.weightKg(), usesWeight, factor);
        Integer iso = scale(current.isometricSeconds(), isometric, factor);
        Integer duration = scale(current.targetDurationSeconds(), true, factor);
        Integer distance = scale(current.distanceMeters(), true, factor);
        int sets = goal == null ? Math.max(1, current.sets() - 1) : goal.clampSets(current.sets() - 1);
        return new Result(build(current, sets, current.reps(), current.restSeconds() + 30, weight, usesWeight,
                duration, distance, iso), daysInactive + " días sin entrenar → carga ×" + factor,
                AdjustmentReason.INACTIVITY);
    }

    /** Recalcula los pesos por serie solo si cambian el peso o las series; si no, conserva los actuales. */
    private static ExerciseParameters build(ExerciseParameters current, int sets, int reps, int rest, Double weight,
                                            boolean usesWeight, Integer duration, Integer distance, Integer iso) {
        boolean sameLoad = sets == current.sets() && java.util.Objects.equals(weight, current.weightKg());
        List<Double> perSet = sameLoad ? current.weightsKg()
                : usesWeight && weight != null && weight > 0 ? warmupWeights(weight, sets) : null;
        // Las repeticiones y el aguante por serie (ADR 0027) se mueven igual que el valor común: si la
        // progresión suma una repetición, la suma a cada serie; si escala el tiempo, escala cada serie.
        List<Integer> repsPerSet = current.repsPerSet() == null ? null : current.repsPerSet().stream()
                .limit(sets).map(r -> r + reps - current.reps()).toList();
        List<Integer> isoPerSet = current.isometricSecondsPerSet() == null || iso == null
                || current.isometricSeconds() == null ? null : current.isometricSecondsPerSet().stream()
                .limit(sets).map(s -> (int) Math.round(s * (double) iso / current.isometricSeconds())).toList();
        return ExerciseParameters.clamped(sets, reps, rest, weight, perSet, duration, distance, iso, repsPerSet,
                isoPerSet);
    }

    private static Double scale(Double value, boolean applies, double factor) {
        if (!applies || value == null) {
            return value;
        }
        return value * factor;
    }

    private static Integer scale(Integer value, boolean applies, double factor) {
        if (!applies || value == null) {
            return value;
        }
        return (int) Math.round(value * factor);
    }
}
