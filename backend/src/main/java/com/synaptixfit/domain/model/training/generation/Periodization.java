package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedDay;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedExercise;
import com.synaptixfit.domain.model.training.generation.RoutineProposal.ProposedWeek;
import java.util.ArrayList;
import java.util.List;

/**
 * Expande la semana tipo a todas las semanas de la rutina con su fase (el sistema heredado solo
 * rellenaba la primera semana y dejaba vacías las demás).
 *
 * <p>Fases: adaptación (80 % de series, 90 % de carga), carga (+2,5 % de carga por cada semana de
 * carga anterior), pico (105 % de carga) y descarga (60 % de series y 70 % de carga, tiempo y
 * distancia). Si el historial pide descarga, la primera semana es de descarga.
 */
public final class Periodization {

    private Periodization() {
    }

    public static WeekType typeFor(int weekNumber, int totalWeeks, boolean requiresDeload) {
        if (requiresDeload && weekNumber == 1) {
            return WeekType.DELOAD;
        }
        return WeekType.forPosition(weekNumber, totalWeeks);
    }

    public static String defaultWeekName(int number, WeekType type) {
        String phase = switch (type) {
            case ADAPTATION -> "Adaptación";
            case LOAD -> "Carga";
            case PEAK -> "Pico";
            case DELOAD -> "Descarga";
        };
        return "Semana " + number + ": " + phase;
    }

    public static List<ProposedWeek> expand(List<ProposedDay> template, int totalWeeks, boolean requiresDeload) {
        int weeks = Math.max(1, Math.min(12, totalWeeks));
        List<ProposedWeek> result = new ArrayList<>();
        int loadWeeksSoFar = 0;
        for (int n = 1; n <= weeks; n++) {
            WeekType type = typeFor(n, weeks, requiresDeload);
            final int loadIndex = loadWeeksSoFar;
            List<ProposedDay> days = template.stream()
                    .map(d -> d.mapExercises(e -> adjust(e, type, loadIndex))).toList();
            if (type == WeekType.LOAD) {
                loadWeeksSoFar++;
            }
            result.add(new ProposedWeek(n, defaultWeekName(n, type), type, days));
        }
        return result;
    }

    static ProposedExercise adjust(ProposedExercise e, WeekType type, int loadIndex) {
        ExerciseParameters p = e.parameters();
        double setFactor;
        double loadFactor;
        double timeFactor = 1.0;
        switch (type) {
            case ADAPTATION -> {
                setFactor = 0.8;
                loadFactor = 0.9;
            }
            case PEAK -> {
                setFactor = 1.0;
                loadFactor = 1.05;
            }
            case DELOAD -> {
                setFactor = 0.6;
                loadFactor = 0.7;
                timeFactor = 0.7;
            }
            default -> {
                setFactor = 1.0;
                loadFactor = 1.0 + 0.025 * loadIndex;
            }
        }
        if (setFactor == 1.0 && loadFactor == 1.0 && timeFactor == 1.0) {
            return e;
        }
        int sets = Math.max(1, (int) Math.round(p.sets() * setFactor));
        Double weight = p.weightKg() == null ? null : p.weightKg() * loadFactor;
        List<Double> perSet = weight != null && weight > 0 ? ProgressionCalculator.warmupWeights(weight, sets) : null;
        Integer duration = p.targetDurationSeconds() == null ? null : (int) Math.round(p.targetDurationSeconds() * timeFactor);
        Integer distance = p.distanceMeters() == null ? null : (int) Math.round(p.distanceMeters() * timeFactor);
        return e.withParameters(ExerciseParameters.clamped(sets, p.reps(), p.restSeconds(), weight, perSet, duration,
                distance, p.isometricSeconds()));
    }
}
