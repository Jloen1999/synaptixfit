package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.AdjustmentReason;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.MeasurementType;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.SessionSet;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import com.synaptixfit.domain.model.training.generation.LoadSuggestion.Metric;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

/**
 * Progresión de cargas dentro de la sesión: para cada ejercicio del día propone la cifra de hoy a partir
 * de la última vez que se hizo, con las mismas reglas que {@link ProgressionCalculator} (RPE de aquella
 * sesión y repeticiones fallidas). Así la sugerencia de después de la sesión y la de dentro coinciden.
 *
 * <p>Reglas propias de esta vista (fórmula en {@code docs/01-architecture/formulas.md}):
 * <ul>
 *   <li>La base es lo que se hizo de verdad (la serie de más peso, el aguante, tiempo o distancia más
 *       largos), no lo planificado: si alguien subió por su cuenta, se progresa desde ahí.</li>
 *   <li>Solo cambia la carga de hoy; las series no (quitar una serie es cosa de la sugerencia de la rutina).</li>
 *   <li>Sin propuesta si la última vez fue hace más de {@value ProgressionCalculator#INACTIVITY_DAYS} días
 *       (manda la descarga por inactividad), si no hubo RPE o si la rutina ya pide esa cifra (la sugerencia
 *       se aplicó: proponerla otra vez la duplicaría).</li>
 * </ul>
 */
public final class LoadSuggestions {

    private LoadSuggestions() {
    }

    /**
     * @param recent sesiones completadas, las más recientes primero
     * @param goal   parámetros del objetivo de la rutina (nulo: rangos por defecto)
     */
    public static List<LoadSuggestion> forDay(List<PlannedExercise> exercises, List<CompletedSessionSummary> recent,
                                              GoalParameters goal, Instant now) {
        List<LoadSuggestion> result = new ArrayList<>();
        for (PlannedExercise p : exercises) {
            suggest(p, recent, goal, now).ifPresent(result::add);
        }
        return result;
    }

    static Optional<LoadSuggestion> suggest(PlannedExercise p, List<CompletedSessionSummary> recent,
                                            GoalParameters goal, Instant now) {
        CompletedSessionSummary last = recent.stream()
                .filter(s -> s.rpe() != null && s.sets().stream().anyMatch(x -> sameExercise(x, p)))
                .findFirst().orElse(null);
        if (last == null
                || Duration.between(last.completedAt(), now).toDays() > ProgressionCalculator.INACTIVITY_DAYS) {
            return Optional.empty();
        }
        List<SessionSet> sets = last.sets().stream().filter(x -> sameExercise(x, p)).map(PerformedSet::set)
                .toList();
        Collection<MeasurementType> types = p.exercise().measurementTypes();
        ExerciseParameters base = performed(p.parameters(), types, sets);
        ProgressionCalculator.Result r = ProgressionCalculator.progress(base, types, last.rpe(), sets, goal);
        if (r.reason() == null) {
            return Optional.empty();
        }
        ExerciseParameters next = r.parameters();
        for (Metric metric : metricsFor(r.reason())) {
            Double before = value(base, metric);
            Double after = value(next, metric);
            if (before == null || after == null || before.equals(after)) {
                continue;
            }
            // La rutina ya pide esa cifra: la sugerencia de después de la sesión se aplicó.
            if (after.equals(value(p.parameters(), metric))) {
                return Optional.empty();
            }
            Integer percent = before > 0 ? (int) Math.round((after - before) / before * 100) : null;
            return Optional.of(new LoadSuggestion(p.id(), p.exerciseId(), metric, before, after, percent,
                    r.reason(), last.rpe(), last.completedAt(), perSet(p.parameters(), metric, before, after)));
        }
        return Optional.empty();
    }

    /**
     * Cifras que puede mover cada motivo: los recortes de rango del objetivo (p. ej. repeticiones por
     * debajo del mínimo) no son una progresión y no se proponen.
     */
    private static List<Metric> metricsFor(AdjustmentReason reason) {
        return switch (reason) {
            case LOW_RPE_MORE_REPS -> List.of(Metric.REPS);
            case LOW_RPE_MORE_WEIGHT -> List.of(Metric.WEIGHT);
            case LOW_RPE_MORE_TIME -> List.of(Metric.DURATION_SECONDS);
            case LOW_RPE_MORE_DISTANCE -> List.of(Metric.DISTANCE_METERS);
            case FAILED_REPS, VERY_HIGH_RPE, VERY_LOW_RPE, INACTIVITY -> List.of(Metric.WEIGHT,
                    Metric.HOLD_SECONDS, Metric.DURATION_SECONDS, Metric.DISTANCE_METERS);
        };
    }

    private static boolean sameExercise(PerformedSet x, PlannedExercise p) {
        return Objects.equals(x.exerciseId(), p.exerciseId());
    }

    /**
     * Parámetros con lo que se hizo de verdad: la serie de más peso (y sus repeticiones) o, si no hay peso,
     * la de más repeticiones; el aguante, el tiempo y la distancia más largos.
     */
    static ExerciseParameters performed(ExerciseParameters plan, Collection<MeasurementType> types,
                                        List<SessionSet> sets) {
        boolean usesWeight = types.contains(MeasurementType.WEIGHT);
        boolean isometric = types.contains(MeasurementType.TIME) && !types.contains(MeasurementType.REPETITIONS)
                && plan.isometricSeconds() != null;
        SessionSet top = sets.stream().filter(s -> s.repsDone() != null && s.repsDone() > 0)
                .max(Comparator.comparing((SessionSet s) -> usesWeight && s.weightKg() != null ? s.weightKg() : 0)
                        .thenComparing(SessionSet::repsDone))
                .orElse(null);
        Double weight = usesWeight && top != null && top.weightKg() != null && top.weightKg() > 0
                ? top.weightKg() : plan.weightKg();
        int reps = top != null ? top.repsDone() : plan.reps();
        Integer longest = sets.stream().map(SessionSet::durationSeconds).filter(Objects::nonNull)
                .max(Integer::compare).orElse(null);
        Integer distance = sets.stream().map(SessionSet::distanceMeters).filter(Objects::nonNull)
                .max(Integer::compare).orElse(plan.distanceMeters());
        Integer iso = isometric && longest != null ? longest : plan.isometricSeconds();
        Integer duration = !isometric && longest != null && plan.targetDurationSeconds() != null
                ? longest : plan.targetDurationSeconds();
        return ExerciseParameters.clamped(plan.sets(), reps, plan.restSeconds(), weight, null, duration, distance,
                iso);
    }

    /**
     * Cifra de cada serie planificada: si la rutina detalla la serie (pirámide), el peso y el aguante se mueven en
     * la misma proporción (peso a 0,5 kg) y las repeticiones en la misma diferencia; si no, la cifra propuesta.
     */
    static List<Double> perSet(ExerciseParameters plan, Metric metric, double before, double after) {
        double ratio = before > 0 ? after / before : 1.0;
        List<Double> out = new ArrayList<>();
        for (int n = 1; n <= plan.sets(); n++) {
            double value = switch (metric) {
                case WEIGHT -> plan.weightsKg() == null || plan.weightForSet(n) == null ? after
                        : ExerciseParameters.roundWeight(plan.weightForSet(n) * ratio);
                case REPS -> plan.repsPerSet() == null ? after
                        : Math.max(1, plan.repsForSet(n) + (int) Math.round(after - before));
                case HOLD_SECONDS -> plan.isometricSecondsPerSet() == null || plan.isometricSecondsForSet(n) == null
                        ? after : Math.round(plan.isometricSecondsForSet(n) * ratio);
                case DURATION_SECONDS, DISTANCE_METERS -> after;
            };
            out.add(value);
        }
        return out;
    }

    private static Double value(ExerciseParameters p, Metric metric) {
        return switch (metric) {
            case WEIGHT -> p.weightKg();
            case REPS -> (double) p.reps();
            case HOLD_SECONDS -> p.isometricSeconds() == null ? null : p.isometricSeconds().doubleValue();
            case DURATION_SECONDS -> p.targetDurationSeconds() == null ? null
                    : p.targetDurationSeconds().doubleValue();
            case DISTANCE_METERS -> p.distanceMeters() == null ? null : p.distanceMeters().doubleValue();
        };
    }
}
