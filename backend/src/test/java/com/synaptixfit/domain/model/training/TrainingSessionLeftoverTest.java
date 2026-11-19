package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Sesión a medias de Inicio (ADR 0059): cuándo hay que cerrarla y cuántos ejercicios se hicieron. */
class TrainingSessionLeftoverTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");

    private static TrainingSession openAt(Instant startedAt, List<SessionSet> sets) {
        return new TrainingSession(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
                SessionType.ROUTINE, startedAt, null, 0, null, null, 0, sets);
    }

    @Test
    void startedTodayLessThanSixHoursAgoIsStillInProgress() {
        Instant now = Instant.parse("2026-11-19T18:00:00Z");
        assertThat(openAt(now.minusSeconds(2 * 3600), List.of()).isLeftover(now)).isFalse();
    }

    @Test
    void openForMoreThanSixHoursIsLeftover() {
        Instant now = Instant.parse("2026-11-19T18:00:00Z");
        assertThat(openAt(now.minusSeconds(7 * 3600), List.of()).isLeftover(now)).isTrue();
    }

    @Test
    void trainingPastMidnightIsStillInProgress() {
        // Empieza a las 23:30 en Madrid (22:30 UTC) y son las 00:30: cambió el día, pero sigue entrenando.
        Instant afterMidnight = Instant.parse("2026-11-18T23:30:00Z");
        assertThat(openAt(Instant.parse("2026-11-18T22:30:00Z"), List.of()).isLeftover(afterMidnight)).isFalse();
    }

    @Test
    void aFinishedSessionIsNeverLeftover() {
        Instant start = Instant.parse("2026-11-17T18:00:00Z");
        TrainingSession done = new TrainingSession(UUID.randomUUID(), UUID.randomUUID(), null, null, SessionType.FREE,
                start, start.plusSeconds(3600), 60, 7, 300.0, 10, List.of());
        assertThat(done.isLeftover(Instant.parse("2026-11-19T18:00:00Z"))).isFalse();
    }

    @Test
    void countsExercisesWithAtLeastOneDoneWorkingSet() {
        UUID squat = UUID.randomUUID();
        UUID press = UUID.randomUUID();
        UUID row = UUID.randomUUID();
        List<SessionSet> sets = List.of(
                new SessionSet(UUID.randomUUID(), squat, 1, 10, 60.0, true, 0, null, null, null, null),
                new SessionSet(UUID.randomUUID(), squat, 2, 10, 60.0, true, 0, null, null, null, null),
                new SessionSet(UUID.randomUUID(), press, 1, 8, 40.0, true, 0, null, null, null, null),
                new SessionSet(UUID.randomUUID(), row, 1, null, null, false, 0, null, null, null, null));
        assertThat(openAt(Instant.parse("2026-11-18T17:10:00Z"), sets).exercisesDone()).isEqualTo(2);
    }

    @Test
    void inARoutineSessionAnAddedExerciseDoesNotCountSoItNeverReadsSevenOfSix() {
        List<SessionSet> sets = List.of(
                new SessionSet(UUID.randomUUID(), UUID.randomUUID(), 1, 10, 60.0, true, 0, null, null, null, null),
                new SessionSet(UUID.randomUUID(), null, 1, 10, 20.0, true, 0, null, null, UUID.randomUUID(), null));
        assertThat(openAt(Instant.parse("2026-11-18T17:10:00Z"), sets).exercisesDone()).isEqualTo(1);
    }

    @Test
    void aSessionFromAnotherDayIsSavedOnThatDayEvenIfNotSixHoursOld() {
        // 22:00 en Madrid (21:00 UTC) y se guarda a la 01:00 con 1 h registrada: termina a las 23:00 del día 18.
        Instant start = Instant.parse("2026-11-18T21:00:00Z");
        Instant now = Instant.parse("2026-11-19T00:00:00Z");
        TrainingSession s = openAt(start, List.of());
        assertThat(s.completionInstant(3600, now, MADRID)).isEqualTo(start.plusSeconds(3600));
        // El mismo día y con menos de 6 h, termina ahora.
        Instant sameDay = Instant.parse("2026-11-18T22:00:00Z");
        assertThat(openAt(Instant.parse("2026-11-18T20:00:00Z"), List.of()).completionInstant(3600, sameDay, MADRID))
                .isEqualTo(sameDay);
    }
}
