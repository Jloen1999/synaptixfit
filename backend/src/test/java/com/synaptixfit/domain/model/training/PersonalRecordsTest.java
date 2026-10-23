package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary;
import com.synaptixfit.domain.model.training.generation.CompletedSessionSummary.PerformedSet;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PersonalRecordsTest {

    private static final UUID BENCH = UUID.randomUUID();
    private static final UUID PULL_UP = UUID.randomUUID();

    private static PerformedSet set(UUID exercise, String name, Integer reps, Double kg, boolean completed) {
        return new PerformedSet(exercise, name, new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, reps, kg,
                completed, 0));
    }

    private static CompletedSessionSummary session(UUID id, String at, PerformedSet... sets) {
        return new CompletedSessionSummary(id, Instant.parse(at), 7, 60, List.of(sets));
    }

    @Test
    void firstPerformanceIsNotABrokenRecordButTheNextImprovementIs() {
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();
        UUID third = UUID.randomUUID();
        List<CompletedSessionSummary> sessions = List.of(
                session(third, "2026-10-17T18:00:00Z", set(BENCH, "Press de banca", 5, 62.5, true)),
                session(first, "2026-10-10T18:00:00Z", set(BENCH, "Press de banca", 8, 60.0, true),
                        set(PULL_UP, "Dominadas", 6, null, true)),
                session(second, "2026-10-13T18:00:00Z", set(BENCH, "Press de banca", 6, 60.0, true),
                        set(PULL_UP, "Dominadas", 8, null, true)));

        Map<UUID, List<PersonalRecord>> broken = PersonalRecords.brokenBySession(sessions);

        assertThat(broken).doesNotContainKey(first);
        assertThat(broken.get(second)).singleElement().satisfies(r -> {
            assertThat(r.exerciseId()).isEqualTo(PULL_UP);
            assertThat(r.kind()).isEqualTo(PersonalRecord.Kind.REPS);
            assertThat(r.reps()).isEqualTo(8);
        });
        assertThat(broken.get(third)).singleElement().satisfies(r -> {
            assertThat(r.kind()).isEqualTo(PersonalRecord.Kind.WEIGHT);
            assertThat(r.weightKg()).isEqualTo(62.5);
        });
    }

    @Test
    void sameWeightWithMoreRepsBeatsAndIncompleteSetsDoNotCount() {
        UUID a = UUID.randomUUID();
        UUID b = UUID.randomUUID();
        List<CompletedSessionSummary> sessions = List.of(
                session(a, "2026-10-01T18:00:00Z", set(BENCH, "Press de banca", 5, 60.0, true)),
                session(b, "2026-10-03T18:00:00Z", set(BENCH, "Press de banca", 6, 60.0, true),
                        set(BENCH, "Press de banca", 3, 80.0, false)));

        assertThat(PersonalRecords.brokenBySession(sessions).get(b)).singleElement()
                .satisfies(r -> assertThat(r.reps()).isEqualTo(6));
    }

    @Test
    void bestListsTheCurrentMarkPerExerciseMostRecentFirst() {
        List<CompletedSessionSummary> sessions = List.of(
                session(UUID.randomUUID(), "2026-10-01T18:00:00Z", set(BENCH, "Press de banca", 5, 60.0, true)),
                session(UUID.randomUUID(), "2026-10-05T18:00:00Z", set(PULL_UP, "Dominadas", 7, null, true)),
                session(UUID.randomUUID(), "2026-10-08T18:00:00Z", set(BENCH, "Press de banca", 5, 55.0, true)));

        List<PersonalRecord> best = PersonalRecords.best(sessions);

        assertThat(best).extracting(PersonalRecord::exerciseId).containsExactly(PULL_UP, BENCH);
        assertThat(best.get(1).weightKg()).isEqualTo(60.0);
    }

    @Test
    void lastBestIsTheBestSetOfTheMostRecentSessionEvenIfItWasNotARecord() {
        List<CompletedSessionSummary> sessions = List.of(
                session(UUID.randomUUID(), "2026-10-08T18:00:00Z", set(BENCH, "Press de banca", 8, 55.0, true),
                        set(BENCH, "Press de banca", 6, 57.5, true)),
                session(UUID.randomUUID(), "2026-10-01T18:00:00Z", set(BENCH, "Press de banca", 5, 60.0, true),
                        set(PULL_UP, "Dominadas", 7, null, true)));

        Map<UUID, PersonalRecord> last = PersonalRecords.lastBest(sessions);

        assertThat(last.get(BENCH).weightKg()).isEqualTo(57.5);
        assertThat(last.get(BENCH).reps()).isEqualTo(6);
        assertThat(last.get(PULL_UP).reps()).isEqualTo(7);
    }
}
