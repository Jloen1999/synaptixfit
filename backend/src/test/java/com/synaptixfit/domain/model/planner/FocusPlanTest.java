package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class FocusPlanTest {

    @Test
    void withoutFatigueTheFullAttentionCycleIsRecommended() {
        FocusPlan plan = FocusPlan.standard();

        assertThat(plan.focusMinutes()).isEqualTo(52);
        assertThat(plan.shortBreakMinutes()).isEqualTo(17);
        assertThat(plan.longBreakMinutes()).isEqualTo(30);
        assertThat(plan.cyclesBeforeLongBreak()).isEqualTo(3);
        assertThat(plan.limitedByFatigue()).isFalse();
    }

    @Test
    void physicalFatigueShortensTheBlockAndKeepsTheBreakProportion() {
        FocusPlan plan = FocusPlan.of(40);

        assertThat(plan.focusMinutes()).isEqualTo(40);
        assertThat(plan.shortBreakMinutes()).isEqualTo(13);
        assertThat(plan.limitedByFatigue()).isTrue();
    }

    @Test
    void theBlockNeverGoesBelowTheMinimumStudyMinutes() {
        FocusPlan plan = FocusPlan.of(10);

        assertThat(plan.focusMinutes()).isEqualTo(25);
        assertThat(plan.shortBreakMinutes()).isEqualTo(8);
    }

    @Test
    void aLongerAllowedBlockStillStopsAtTheAttentionCycle() {
        assertThat(FocusPlan.of(90).focusMinutes()).isEqualTo(52);
        assertThat(FocusPlan.of(60).limitedByFatigue()).isFalse();
    }

    @Test
    void theRecommendedBreaksAreAlwaysInsideTheLimitsToChooseThem() {
        for (int max : new int[] {10, 25, 40, 52, 90}) {
            FocusPlan plan = FocusPlan.of(max);
            assertThat(plan.shortBreakMinutes()).isBetween(FocusPlan.MIN_SHORT_BREAK_MINUTES,
                    FocusPlan.MAX_SHORT_BREAK_MINUTES);
            assertThat(plan.longBreakMinutes()).isBetween(FocusPlan.MIN_LONG_BREAK_MINUTES,
                    FocusPlan.MAX_LONG_BREAK_MINUTES);
        }
    }
}
