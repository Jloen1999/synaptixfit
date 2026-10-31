package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Resumen final de la sesión: volumen, récords y comparación con la anterior comparable. */
class SessionHighlightsTest {

    private static final UUID BENCH = UUID.randomUUID();
    private static final UUID RUN = UUID.randomUUID();

    private static PerformedSet set(UUID exercise, Double kg, int reps, boolean done) {
        return new PerformedSet(exercise, "Ejercicio",
                new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, reps, kg, done, 0));
    }

    private static CompletedSessionSummary session(UUID id, String at, int minutes, PerformedSet... sets) {
        return new CompletedSessionSummary(id, Instant.parse(at), 7, minutes, List.of(sets));
    }

    @Test
    void sumsVolumeComparesWithThePreviousComparableSessionAndListsRecords() {
        UUID first = UUID.randomUUID();
        UUID other = UUID.randomUUID();
        UUID last = UUID.randomUUID();
        List<CompletedSessionSummary> sessions = List.of(
                session(first, "2026-10-20T18:00:00Z", 50, set(BENCH, 60.0, 8, true)),
                // Más reciente, pero sin ejercicios en común: no es la sesión comparable.
                session(other, "2026-10-22T18:00:00Z", 30, set(RUN, null, 1, true)),
                session(last, "2026-10-24T18:00:00Z", 55, set(BENCH, 65.0, 8, true), set(BENCH, 65.0, 6, true),
                        set(BENCH, 70.0, 3, false)));

        SessionHighlights h = SessionHighlights.of(last, sessions).orElseThrow();

        assertThat(h.volumeKg()).isEqualTo(65.0 * 8 + 65.0 * 6); // la serie sin completar no cuenta
        assertThat(h.totalReps()).isEqualTo(14);
        assertThat(h.completedSets()).isEqualTo(2);
        assertThat(h.previousVolumeKg()).isEqualTo(60.0 * 8);
        assertThat(h.previousDurationMinutes()).isEqualTo(50);
        assertThat(h.records()).singleElement().satisfies(r -> assertThat(r.weightKg()).isEqualTo(65.0));
    }

    @Test
    void theFirstSessionHasNoComparisonNorRecordsAndAnUnknownSessionIsEmpty() {
        UUID only = UUID.randomUUID();
        List<CompletedSessionSummary> sessions = List.of(
                session(only, "2026-10-20T18:00:00Z", 40, set(BENCH, 50.0, 10, true)));

        SessionHighlights h = SessionHighlights.of(only, sessions).orElseThrow();
        assertThat(h.previousVolumeKg()).isNull();
        assertThat(h.records()).isEmpty();
        assertThat(SessionHighlights.of(UUID.randomUUID(), sessions)).isEmpty();
    }
}
