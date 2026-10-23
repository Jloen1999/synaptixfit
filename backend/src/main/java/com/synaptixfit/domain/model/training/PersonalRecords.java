package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Récords personales a partir de las sesiones completadas, recorridas en orden cronológico.
 *
 * <p>Reglas: solo cuentan las series completadas con repeticiones. Con carga ({@code peso > 0}) manda
 * el peso y, a igual peso, las repeticiones; sin carga, las repeticiones. Un ejercicio que se hace por
 * primera vez marca la referencia pero no cuenta como récord batido: si no, toda primera sesión
 * llenaría el historial de «récords».
 */
public final class PersonalRecords {

    private PersonalRecords() {
    }

    /** Récords batidos en cada sesión (por id de sesión); las sesiones sin récord no aparecen. */
    public static Map<UUID, List<PersonalRecord>> brokenBySession(List<CompletedSessionSummary> sessions) {
        Map<UUID, List<PersonalRecord>> broken = new HashMap<>();
        walk(sessions, (record, isNew) -> {
            if (!isNew) {
                broken.computeIfAbsent(record.sessionId(), k -> new ArrayList<>()).add(record);
            }
        });
        return broken;
    }

    /** Mejor marca actual de cada ejercicio, de la más reciente a la más antigua. */
    public static List<PersonalRecord> best(List<CompletedSessionSummary> sessions) {
        Map<UUID, PersonalRecord> best = new LinkedHashMap<>();
        walk(sessions, (record, isNew) -> best.put(record.exerciseId(), record));
        return best.values().stream()
                .sorted(Comparator.comparing(PersonalRecord::achievedAt).reversed())
                .toList();
    }

    /**
     * Lo que hizo la última vez en cada ejercicio: su mejor serie de la sesión más reciente en la que
     * aparece. Sirve de referencia al registrar la siguiente serie («La última vez: 40 kg × 8»).
     */
    public static Map<UUID, PersonalRecord> lastBest(List<CompletedSessionSummary> sessions) {
        Map<UUID, PersonalRecord> last = new LinkedHashMap<>();
        sessions.stream()
                .sorted(Comparator.comparing(CompletedSessionSummary::completedAt))
                .forEach(session -> last.putAll(sessionBest(session)));
        return last;
    }

    private interface Listener {
        /** {@code isNew}: primera marca del ejercicio (no es un récord «batido»). */
        void improved(PersonalRecord record, boolean isNew);
    }

    private static void walk(List<CompletedSessionSummary> sessions, Listener listener) {
        Map<UUID, PersonalRecord> current = new HashMap<>();
        List<CompletedSessionSummary> ordered = sessions.stream()
                .sorted(Comparator.comparing(CompletedSessionSummary::completedAt))
                .toList();
        for (CompletedSessionSummary session : ordered) {
            // Mejor serie de cada ejercicio en esta sesión; se compara con lo anterior una sola vez.
            for (PersonalRecord candidate : sessionBest(session).values()) {
                PersonalRecord previous = current.get(candidate.exerciseId());
                if (previous == null) {
                    current.put(candidate.exerciseId(), candidate);
                    listener.improved(candidate, true);
                } else if (beats(candidate, previous)) {
                    current.put(candidate.exerciseId(), candidate);
                    listener.improved(candidate, false);
                }
            }
        }
    }

    private static Map<UUID, PersonalRecord> sessionBest(CompletedSessionSummary session) {
        Map<UUID, PersonalRecord> best = new LinkedHashMap<>();
        for (PerformedSet performed : session.sets()) {
            PersonalRecord candidate = candidate(performed, session);
            if (candidate == null) {
                continue;
            }
            PersonalRecord previous = best.get(candidate.exerciseId());
            if (previous == null || beats(candidate, previous)) {
                best.put(candidate.exerciseId(), candidate);
            }
        }
        return best;
    }

    private static PersonalRecord candidate(PerformedSet performed, CompletedSessionSummary session) {
        SessionSet set = performed.set();
        if (performed.exerciseId() == null || !set.completed() || set.repsDone() == null || set.repsDone() <= 0) {
            return null;
        }
        boolean loaded = set.weightKg() != null && set.weightKg() > 0;
        return new PersonalRecord(performed.exerciseId(), performed.exerciseName(),
                loaded ? PersonalRecord.Kind.WEIGHT : PersonalRecord.Kind.REPS, loaded ? set.weightKg() : null,
                set.repsDone(), session.sessionId(), session.completedAt());
    }

    /** Si {@code a} supera a {@code b}. Una marca con carga siempre supera a una sin carga. */
    static boolean beats(PersonalRecord a, PersonalRecord b) {
        if (a.kind() != b.kind()) {
            return a.kind() == PersonalRecord.Kind.WEIGHT;
        }
        if (a.kind() == PersonalRecord.Kind.WEIGHT) {
            int byWeight = Double.compare(a.weightKg(), b.weightKg());
            return byWeight > 0 || (byWeight == 0 && a.reps() > b.reps());
        }
        return a.reps() > b.reps();
    }
}
