package com.synaptixfit.domain.model.badge;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Comodines de racha: se ganan cada 7 días seguidos (máximo 2) y salvan un día sin actividad. */
class StreakFreezesTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 10, 31);

    /** Días activos de {@code from} a {@code to} días atrás (ambos incluidos). */
    private static Set<LocalDate> active(int from, int to) {
        Set<LocalDate> days = new HashSet<>();
        for (int i = to; i <= from; i++) {
            days.add(TODAY.minusDays(i));
        }
        return days;
    }

    @Test
    void aWeekInARowEarnsAFreezeThatSavesTheNextMissedDay() {
        Set<LocalDate> days = active(9, 3);          // 7 días seguidos
        days.addAll(active(1, 0));                    // ayer y hoy; anteayer (2) sin actividad

        StreakFreezes.Run run = StreakFreezes.run(days, TODAY);

        assertThat(run.currentDays()).isEqualTo(9);
        assertThat(run.frozenDays()).containsExactly(TODAY.minusDays(2));
        assertThat(run.available()).isZero();
    }

    @Test
    void withoutAFreezeAMissedDayBreaksTheStreak() {
        Set<LocalDate> days = active(5, 3);
        days.add(TODAY);

        assertThat(StreakFreezes.run(days, TODAY).currentDays()).isEqualTo(1);
    }

    @Test
    void atMostTwoFreezesAreKeptAndTwoMissedDaysCanBeSaved() {
        Set<LocalDate> days = active(30, 3);         // 28 días seguidos: 4 comodines, se guardan 2

        StreakFreezes.Run beforeGap = StreakFreezes.run(days, TODAY.minusDays(2));
        StreakFreezes.Run afterGap = StreakFreezes.run(days, TODAY);

        assertThat(beforeGap.available()).isEqualTo(StreakFreezes.MAX_FREEZES);
        // Hace 2 días y ayer sin actividad: los dos comodines; hoy aún no cuenta.
        assertThat(afterGap.currentDays()).isEqualTo(28);
        assertThat(afterGap.frozenDays()).hasSize(2);
        assertThat(afterGap.available()).isZero();
    }

    @Test
    void todayWithoutActivityNeitherBreaksNorSpends() {
        StreakFreezes.Run run = StreakFreezes.run(active(7, 1), TODAY);

        assertThat(run.currentDays()).isEqualTo(7);
        assertThat(run.available()).isEqualTo(1);
        assertThat(run.frozenDays()).isEmpty();
    }

    @Test
    void aStreakProtectedByAFreezeIsNotAtRisk() {
        StreakStatus status = StreakStatus.compute(active(7, 1), LocalDateTime.of(TODAY, java.time.LocalTime.of(22, 0)));

        assertThat(status.atRisk()).isFalse();
        assertThat(status.freezesAvailable()).isEqualTo(1);
        assertThat(StreakStatus.compute(active(3, 1), LocalDateTime.of(TODAY, java.time.LocalTime.of(22, 0)))
                .atRisk()).isTrue();
    }
}
