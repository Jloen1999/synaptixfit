package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.RepRange;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.load.LoadProfile;
import com.synaptixfit.domain.model.training.load.LoadStep;
import java.util.Collection;
import java.util.List;
import java.util.Objects;

/**
 * Sobrecarga progresiva (doble progresión) y degradación por inactividad, también para ejercicios
 * por tiempo, distancia e isométricos.
 *
 * <p>Con rango de repeticiones del ejercicio ({@link RepRange}, ADR 0054), doble progresión: cuando todas las series
 * llegan al tope del rango con el esfuerzo pedido (RPE de la sesión ≤ 10 − repeticiones que deben sobrar) el peso sube
 * un escalón del material ({@link LoadStep}) y las repeticiones vuelven al mínimo; si no, +1 repetición hasta el tope.
 * Si no se llega al mínimo del rango, se repite; dos sesiones seguidas así, el peso baja un 10 %.
 *
 * <p>Sin rango (rutinas generadas o hechas a mano), las reglas de siempre: con repeticiones fallidas la carga baja
 * {@code 5 %} por fallo (entre 5 % y 30 %) y se quita una serie; RPE ≥ 9,5 → carga −15 %; RPE ≤ 5 → carga +10 %
 * (isométrico +10 s); RPE ≤ 7 → +1 repetición o, en el tope del rango del objetivo, un escalón del material y vuelta
 * al mínimo de repeticiones (tiempo/distancia +10 %). Con más de 14 días sin entrenar la carga baja al 80 % (70 % a
 * partir de 21 días), se quita una serie y se añaden 30 s de descanso.
 *
 * <p>El peso es el mismo en todas las series de trabajo: el calentamiento va aparte (ADR 0031), así que ya no se
 * reparte en 50 % / 75 % / 100 %.
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

    public static Result progress(ExerciseParameters current, Collection<MeasurementType> types, double lastRpe,
                                  List<SessionSet> performedSets, GoalParameters goal) {
        return progress(current, types, lastRpe, performedSets, goal, null, false);
    }

    /**
     * @param load             cómo se carga el ejercicio (decide el escalón de peso); nulo si no se sabe
     * @param belowMinLastTime la sesión anterior con este ejercicio tampoco llegó al mínimo del rango
     */
    public static Result progress(ExerciseParameters current, Collection<MeasurementType> types, double lastRpe,
                                  List<SessionSet> performedSets, GoalParameters goal, LoadProfile load,
                                  boolean belowMinLastTime) {
        if (current.repRange() != null && types.contains(MeasurementType.REPETITIONS)
                && current.isometricSeconds() == null) {
            return doubleProgression(current, types, lastRpe, performedSets, load, belowMinLastTime);
        }
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
                    weight = LoadStep.up(weight, load);
                    reps = goal == null ? 6 : goal.repsMin();
                    log = "RPE bajo → un escalón más de peso y repeticiones al mínimo";
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

        // Lo que cambie el peso acaba en un peso que existe en ese material (ADR 0054).
        if (usesWeight && weight != null && load != null && !Objects.equals(weight, current.weightKg())) {
            weight = LoadStep.floor(weight, load);
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

    /**
     * Doble progresión con el rango del ejercicio (ver la cabecera). Las series y el descanso no cambian: son los de
     * la plantilla.
     */
    private static Result doubleProgression(ExerciseParameters current, Collection<MeasurementType> types,
                                            double lastRpe, List<SessionSet> performedSets, LoadProfile load,
                                            boolean belowMinLastTime) {
        RepRange range = current.repRange();
        List<SessionSet> done = performedSets == null ? List.of() : performedSets.stream()
                .filter(s -> s.repsDone() != null).toList();
        if (done.isEmpty()) {
            return new Result(current, null, null);
        }
        boolean usesWeight = types.contains(MeasurementType.WEIGHT);
        Double weight = current.weightKg();
        boolean loaded = usesWeight && weight != null && weight > 0;
        boolean belowMin = done.stream().anyMatch(s -> s.repsDone() < range.min());
        boolean allSets = done.size() >= current.sets();
        boolean effortOk = lastRpe <= range.targetRpe() && done.stream().noneMatch(SessionSet::toFailure);
        boolean allTop = allSets && done.stream().allMatch(s -> s.repsDone() >= range.max());
        boolean allReached = allSets && done.stream().allMatch(s -> s.repsDone() >= current.reps());
        if (belowMin) {
            if (belowMinLastTime && loaded) {
                return changed(current, range.min(), LoadStep.reduce(weight, 10, load),
                        "Dos sesiones sin llegar al mínimo del rango → peso −10 %", AdjustmentReason.FAILED_REPS);
            }
            // Sin llegar al mínimo una sola vez: se repite el mismo peso (un mal día no baja nada).
            return new Result(current, null, null);
        }
        if (allTop && effortOk && loaded) {
            double next = LoadStep.up(weight, load);
            if (next > weight) {
                return changed(current, range.min(), next, "Tope del rango → un escalón más de peso",
                        AdjustmentReason.LOW_RPE_MORE_WEIGHT);
            }
        }
        if (allReached && effortOk && current.reps() < range.max()) {
            return changed(current, range.clamp(current.reps() + 1), weight, "Esfuerzo bien → +1 repetición",
                    AdjustmentReason.LOW_RPE_MORE_REPS);
        }
        return new Result(current, null, null);
    }

    private static Result changed(ExerciseParameters current, int reps, Double weight, String log,
                                  AdjustmentReason reason) {
        boolean sameWeight = Objects.equals(weight, current.weightKg());
        ExerciseParameters next = new ExerciseParameters(current.sets(), reps, current.restSeconds(), weight,
                sameWeight ? current.weightsKg() : null, current.targetDurationSeconds(), current.distanceMeters(),
                current.isometricSeconds(), current.repsPerSet() == null ? null : current.repsPerSet().stream()
                        .map(r -> Math.max(1, r + reps - current.reps())).toList(),
                current.isometricSecondsPerSet(), current.repRange());
        return new Result(next, log, reason);
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

    /**
     * Conserva los pesos por serie solo si no cambian ni el peso ni las series; si cambian, el peso es el mismo en
     * todas las series de trabajo.
     */
    private static ExerciseParameters build(ExerciseParameters current, int sets, int reps, int rest, Double weight,
                                            boolean usesWeight, Integer duration, Integer distance, Integer iso) {
        boolean sameLoad = sets == current.sets() && Objects.equals(weight, current.weightKg());
        List<Double> perSet = sameLoad ? current.weightsKg() : null;
        // Las repeticiones y el aguante por serie (ADR 0027) se mueven igual que el valor común: si la
        // progresión suma una repetición, la suma a cada serie; si escala el tiempo, escala cada serie.
        List<Integer> repsPerSet = current.repsPerSet() == null ? null : current.repsPerSet().stream()
                .limit(sets).map(r -> r + reps - current.reps()).toList();
        List<Integer> isoPerSet = current.isometricSecondsPerSet() == null || iso == null
                || current.isometricSeconds() == null ? null : current.isometricSecondsPerSet().stream()
                .limit(sets).map(s -> (int) Math.round(s * (double) iso / current.isometricSeconds())).toList();
        return ExerciseParameters.clamped(sets, reps, rest, weight, perSet, duration, distance, iso, repsPerSet,
                isoPerSet).withRepRange(current.repRange());
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
