package com.synaptixfit.domain.model.training.generation;

import com.synaptixfit.domain.model.training.SessionSet;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;

/**
 * Historial reciente de entrenamiento que alimenta el generador y la progresión.
 *
 * <p>{@code requiresDeload} (detección heredada de periodización): RPE medio de las 3 últimas
 * semanas &gt; 8, 3 o más semanas consecutivas entrenando y volumen semanal decreciente, o una
 * puntuación de fatiga del check-in de hoy &gt; 50.
 */
public record TrainingHistory(int totalCompletedSessions, double averageRpe, Set<String> recentExerciseNames,
                              Integer daysSinceLastSession, Map<UUID, ExercisePerformance> performances,
                              int consecutiveWeeks, boolean requiresDeload) {

    public static final TrainingHistory EMPTY = new TrainingHistory(0, 0, Set.of(), null, Map.of(), 0, false);

    public TrainingHistory {
        recentExerciseNames = Set.copyOf(recentExerciseNames == null ? Set.of() : recentExerciseNames);
        performances = Map.copyOf(performances == null ? Map.of() : performances);
    }

    /** Últimas series registradas de un ejercicio y el RPE de esa sesión. */
    public record ExercisePerformance(UUID exerciseId, String exerciseName, List<SessionSet> lastSets, double rpe) {
        public ExercisePerformance {
            lastSets = List.copyOf(lastSets);
        }
    }

    /**
     * @param sessions         sesiones completadas, de la más reciente a la más antigua
     * @param today            fecha actual en la zona del usuario
     * @param zone             zona para agrupar por semanas
     * @param todayFatigueScore puntuación de fatiga del check-in de hoy (null si no hay)
     */
    public static TrainingHistory from(List<CompletedSessionSummary> sessions, LocalDate today, ZoneId zone,
                                       Integer todayFatigueScore) {
        if (sessions == null || sessions.isEmpty()) {
            boolean deload = todayFatigueScore != null && todayFatigueScore > 50;
            return new TrainingHistory(0, 0, Set.of(), null, Map.of(), 0, deload);
        }
        List<CompletedSessionSummary> sorted = new ArrayList<>(sessions);
        sorted.sort(Comparator.comparing(CompletedSessionSummary::completedAt).reversed());

        double avgRpe = sorted.stream().filter(s -> s.rpe() != null).mapToInt(CompletedSessionSummary::rpe)
                .average().orElse(0);
        LocalDate last = LocalDate.ofInstant(sorted.getFirst().completedAt(), zone);
        int daysSince = (int) ChronoUnit.DAYS.between(last, today);

        LocalDate fourWeeksAgo = today.minusDays(28);
        List<CompletedSessionSummary> recent = sorted.stream()
                .filter(s -> !LocalDate.ofInstant(s.completedAt(), zone).isBefore(fourWeeksAgo)).toList();

        Set<String> recentNames = new HashSet<>();
        Map<UUID, ExercisePerformance> performances = new LinkedHashMap<>();
        for (CompletedSessionSummary s : recent.stream().limit(4).toList()) {
            Map<UUID, List<SessionSet>> byExercise = new LinkedHashMap<>();
            Map<UUID, String> names = new LinkedHashMap<>();
            for (CompletedSessionSummary.PerformedSet ps : s.sets()) {
                if (ps.exerciseId() == null) {
                    continue;
                }
                byExercise.computeIfAbsent(ps.exerciseId(), k -> new ArrayList<>()).add(ps.set());
                names.put(ps.exerciseId(), ps.exerciseName());
                if (ps.exerciseName() != null) {
                    recentNames.add(ps.exerciseName().toLowerCase(Locale.ROOT));
                }
            }
            double rpe = s.rpe() == null ? avgRpe : s.rpe();
            byExercise.forEach((exerciseId, sets) -> performances.putIfAbsent(exerciseId,
                    new ExercisePerformance(exerciseId, names.get(exerciseId), sets, rpe)));
        }

        // Semanas consecutivas (desde la más reciente) y volumen por semana de las 3 últimas semanas.
        TreeMap<LocalDate, Integer> minutesByWeek = new TreeMap<>();
        LocalDate threeWeeksAgo = today.minusDays(21);
        double rpeSum = 0;
        int rpeCount = 0;
        for (CompletedSessionSummary s : sorted) {
            LocalDate d = LocalDate.ofInstant(s.completedAt(), zone);
            if (d.isBefore(threeWeeksAgo)) {
                continue;
            }
            minutesByWeek.merge(d.with(DayOfWeek.MONDAY), s.durationMinutes(), Integer::sum);
            if (s.rpe() != null) {
                rpeSum += s.rpe();
                rpeCount++;
            }
        }
        int consecutive = consecutiveWeeks(sorted, zone);
        List<Integer> volumes = new ArrayList<>(minutesByWeek.values());
        boolean decreasing = volumes.size() >= 3
                && volumes.get(volumes.size() - 1) < volumes.get(volumes.size() - 2)
                && volumes.get(volumes.size() - 2) < volumes.get(volumes.size() - 3);
        double recentRpe = rpeCount == 0 ? 0 : rpeSum / rpeCount;
        boolean deload = (recentRpe > 8.0 && consecutive >= 3 && decreasing)
                || (todayFatigueScore != null && todayFatigueScore > 50);

        return new TrainingHistory(sorted.size(), avgRpe, recentNames, daysSince, performances, consecutive, deload);
    }

    private static int consecutiveWeeks(List<CompletedSessionSummary> sortedDesc, ZoneId zone) {
        int count = 0;
        LocalDate previous = null;
        for (CompletedSessionSummary s : sortedDesc) {
            LocalDate week = LocalDate.ofInstant(s.completedAt(), zone).with(DayOfWeek.MONDAY);
            if (previous == null) {
                count = 1;
                previous = week;
            } else if (week.equals(previous)) {
                continue;
            } else if (ChronoUnit.DAYS.between(week, previous) == 7) {
                count++;
                previous = week;
            } else {
                break;
            }
        }
        return count;
    }
}
