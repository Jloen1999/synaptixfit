package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Lo destacable de una sesión terminada, para el resumen final («momento wow» de Strong o Hevy):
 * volumen movido, récords batidos y comparación con la sesión anterior comparable.
 *
 * <p>Volumen = Σ peso × repeticiones de las series completadas (las de peso corporal suman 0 kg pero cuentan en
 * repeticiones). La sesión anterior comparable es la última completada antes que esta que comparte algún
 * ejercicio; sin ella no hay comparación.
 *
 * @param previousVolumeKg volumen de la sesión anterior comparable (null si no hay)
 */
public record SessionHighlights(UUID sessionId, double volumeKg, int totalReps, int completedSets,
                                List<PersonalRecord> records, Double previousVolumeKg,
                                Integer previousDurationMinutes) {

    public SessionHighlights {
        records = List.copyOf(records);
    }

    /** @param sessions sesiones completadas del usuario (incluida la de {@code sessionId}) */
    public static Optional<SessionHighlights> of(UUID sessionId, List<CompletedSessionSummary> sessions) {
        Optional<CompletedSessionSummary> current = sessions.stream()
                .filter(s -> s.sessionId().equals(sessionId)).findFirst();
        if (current.isEmpty()) {
            return Optional.empty();
        }
        CompletedSessionSummary session = current.get();
        Set<UUID> exercises = exercisesOf(session);
        Optional<CompletedSessionSummary> previous = sessions.stream()
                .filter(s -> s.completedAt().isBefore(session.completedAt()))
                .filter(s -> exercisesOf(s).stream().anyMatch(exercises::contains))
                .max(Comparator.comparing(CompletedSessionSummary::completedAt));
        List<PersonalRecord> broken = PersonalRecords.brokenBySession(sessions).getOrDefault(sessionId, List.of());
        return Optional.of(new SessionHighlights(sessionId, volume(session), reps(session), completedSets(session),
                broken, previous.map(SessionHighlights::volume).orElse(null),
                previous.map(CompletedSessionSummary::durationMinutes).orElse(null)));
    }

    private static Set<UUID> exercisesOf(CompletedSessionSummary s) {
        return s.sets().stream().map(CompletedSessionSummary.PerformedSet::exerciseId).filter(Objects::nonNull)
                .collect(Collectors.toSet());
    }

    static double volume(CompletedSessionSummary s) {
        return s.sets().stream().map(CompletedSessionSummary.PerformedSet::set)
                .filter(set -> set.completed() && set.repsDone() != null && set.weightKg() != null)
                .mapToDouble(set -> set.weightKg() * set.repsDone())
                .sum();
    }

    private static int reps(CompletedSessionSummary s) {
        return s.sets().stream().map(CompletedSessionSummary.PerformedSet::set)
                .filter(set -> set.completed() && set.repsDone() != null)
                .mapToInt(SessionSet::repsDone).sum();
    }

    private static int completedSets(CompletedSessionSummary s) {
        return (int) s.sets().stream().filter(p -> p.set().completed()).count();
    }
}
