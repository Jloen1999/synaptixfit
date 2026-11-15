package com.synaptixfit.domain.model.badge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.badge.StreakPauseLimitReachedException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Pausar racha» (ADR 0042): días neutros, topes de 7 seguidos y 14 en 90 días, y «Reanudar». */
class StreakPauseTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 11, 15);
    private static final UUID USER = UUID.randomUUID();
    private static final Instant NOW = Instant.parse("2026-11-15T10:00:00Z");

    private static StreakPause pause(LocalDate from, LocalDate to) {
        return new StreakPause(UUID.randomUUID(), USER, from, to, NOW);
    }

    private static Set<LocalDate> active(int from, int to) {
        Set<LocalDate> days = new HashSet<>();
        for (int i = to; i <= from; i++) {
            days.add(TODAY.minusDays(i));
        }
        return days;
    }

    @Test
    void aPauseStartsTodayAndLastsSevenDaysAtMost() {
        StreakPause p = StreakPause.start(USER, List.of(), TODAY, NOW);

        assertThat(p.from()).isEqualTo(TODAY);
        assertThat(p.to()).isEqualTo(TODAY.plusDays(StreakPause.MAX_CONSECUTIVE_DAYS - 1));
    }

    @Test
    void theWindowCapsThePausedDaysAtFourteen() {
        // Diez días en pausa en el último trimestre: quedan cuatro.
        List<StreakPause> used = List.of(pause(TODAY.minusDays(40), TODAY.minusDays(34)),
                pause(TODAY.minusDays(20), TODAY.minusDays(18)));

        assertThat(StreakPause.daysLeft(used, TODAY)).isEqualTo(4);
        assertThat(StreakPause.start(USER, used, TODAY, NOW).to())
                .isEqualTo(TODAY.plusDays(3));
    }

    @Test
    void pausesOlderThanTheWindowNoLongerCount() {
        List<StreakPause> old = List.of(pause(TODAY.minusDays(120), TODAY.minusDays(100)));

        assertThat(StreakPause.daysLeft(old, TODAY)).isEqualTo(StreakPause.MAX_CONSECUTIVE_DAYS);
    }

    @Test
    void withoutDaysLeftPausingFails() {
        List<StreakPause> used = List.of(pause(TODAY.minusDays(30), TODAY.minusDays(24)),
                pause(TODAY.minusDays(10), TODAY.minusDays(4)));

        assertThatThrownBy(() -> StreakPause.start(USER, used, TODAY, NOW))
                .isInstanceOf(StreakPauseLimitReachedException.class);
    }

    @Test
    void resumingEndsThePauseYesterdayOrDropsItIfItStartedToday() {
        StreakPause running = pause(TODAY.minusDays(2), TODAY.plusDays(4));

        assertThat(running.resumedOn(TODAY)).get().extracting(StreakPause::to).isEqualTo(TODAY.minusDays(1));
        assertThat(pause(TODAY, TODAY.plusDays(6)).resumedOn(TODAY)).isEmpty();
    }

    @Test
    void pausedDaysNeitherBreakNorAddNorSpendAFreeDay() {
        // Activo hace 6-3 días, en pausa hace 2 y 1 días (sin actividad), activo hoy.
        Set<LocalDate> days = active(6, 3);
        days.add(TODAY);
        List<StreakPause> pauses = List.of(pause(TODAY.minusDays(2), TODAY.minusDays(1)));

        StreakStatus status = StreakStatus.compute(days, pauses, TODAY.atTime(12, 0));

        assertThat(status.currentDays()).isEqualTo(5);
        assertThat(status.frozenDays()).isEmpty();
        assertThat(status.pause()).isNull();
    }

    @Test
    void activityOnAPausedDayStillCounts() {
        Set<LocalDate> days = active(3, 0);
        List<StreakPause> pauses = List.of(pause(TODAY.minusDays(1), TODAY.plusDays(5)));

        assertThat(StreakStatus.compute(days, pauses, TODAY.atTime(12, 0)).currentDays()).isEqualTo(4);
    }

    @Test
    void whilePausedTheStreakIsNotAtRiskAndCannotBePausedAgain() {
        Set<LocalDate> days = active(5, 1);
        List<StreakPause> pauses = List.of(pause(TODAY, TODAY.plusDays(6)));

        StreakStatus status = StreakStatus.compute(days, pauses, TODAY.atTime(LocalTime.of(22, 0)));

        assertThat(status.atRisk()).isFalse();
        assertThat(status.pause()).isNotNull();
        assertThat(status.canPause()).isFalse();
        assertThat(status.pauseDaysLeft()).isZero();
    }

    @Test
    void canPauseOnlyWithAStreakToProtect() {
        assertThat(StreakStatus.compute(Set.of(), List.of(), TODAY.atTime(12, 0)).canPause()).isFalse();
        assertThat(StreakStatus.compute(active(3, 1), List.of(), TODAY.atTime(12, 0)).canPause()).isTrue();
    }
}
