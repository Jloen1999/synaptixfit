package com.synaptixfit.domain.model.training;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.dashboard.Dashboard;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** «Hoy toca: suave / normal / fuerte» (ADR 0042) y cuándo se enseña. */
class TodayIntensityTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 11, 15);

    private static DailyCheckIn checkIn(int sleep, int energy, int soreness, List<String> pain, boolean ready) {
        return new DailyCheckIn(UUID.randomUUID(), UUID.randomUUID(), TODAY, sleep, 2, energy, soreness, pain, ready,
                null, Instant.now());
    }

    @Test
    void anyAdaptationMakesItEasy() {
        SessionAdaptation adapted = SessionAdaptation.of(1.0, true, null);

        assertThat(TodayIntensity.of(adapted, checkIn(5, 5, 1, List.of(), true))).isEqualTo(TodayIntensity.EASY);
    }

    @Test
    void feelingWellWithoutReasonsToCutMakesItHard() {
        assertThat(TodayIntensity.of(SessionAdaptation.NONE, checkIn(4, 4, 2, List.of(), true)))
                .isEqualTo(TodayIntensity.HARD);
    }

    @Test
    void withoutCheckInOrWithSomethingOffItIsNormal() {
        assertThat(TodayIntensity.of(SessionAdaptation.NONE, null)).isEqualTo(TodayIntensity.NORMAL);
        assertThat(TodayIntensity.of(SessionAdaptation.NONE, checkIn(3, 5, 1, List.of(), true)))
                .isEqualTo(TodayIntensity.NORMAL);
        assertThat(TodayIntensity.of(SessionAdaptation.NONE, checkIn(5, 5, 3, List.of(), true)))
                .isEqualTo(TodayIntensity.NORMAL);
        assertThat(TodayIntensity.of(SessionAdaptation.NONE, checkIn(5, 5, 1, List.of("rodilla"), true)))
                .isEqualTo(TodayIntensity.NORMAL);
        assertThat(TodayIntensity.of(SessionAdaptation.NONE, checkIn(5, 5, 1, List.of(), false)))
                .isEqualTo(TodayIntensity.NORMAL);
    }

    @Test
    void itShowsOnlyWithTrainingToDo() {
        Dashboard.TodayEvent sport = sportEvent(false);

        assertThat(Dashboard.trainsToday(null, List.of(), TODAY)).isFalse();
        assertThat(Dashboard.trainsToday(null, List.of(sport), TODAY)).isTrue();
        assertThat(Dashboard.trainsToday(null, List.of(sportEvent(true)), TODAY)).isFalse();
    }

    private static Dashboard.TodayEvent sportEvent(boolean completed) {
        Instant start = Instant.parse("2026-11-15T17:00:00Z");
        return new Dashboard.TodayEvent(Dashboard.TodayEvent.Kind.BLOCK, UUID.randomUUID(), "Entreno", "deporte",
                start, start.plusSeconds(3600), completed, null, null, null, null, List.of());
    }
}
