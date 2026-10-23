package com.synaptixfit.domain.model.badge;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** Criterios de insignias y racha diaria. */
class BadgeRulesTest {

    private static final LocalDate TODAY = LocalDate.parse("2026-10-14"); // miércoles

    private static Set<LocalDate> lastDays(LocalDate end, int n) {
        return java.util.stream.IntStream.range(0, n).mapToObj(end::minusDays)
                .collect(java.util.stream.Collectors.toSet());
    }

    // ---------------------------------------------------------------- racha

    @Test
    void streakStaysAliveUntilTheDayEndsWhenLastActivityWasYesterday() {
        Set<LocalDate> days = lastDays(TODAY.minusDays(1), 3);
        StreakStatus morning = StreakStatus.compute(days, TODAY.atTime(9, 0));
        assertThat(morning.currentDays()).isEqualTo(3);
        assertThat(morning.activeToday()).isFalse();
        assertThat(morning.atRisk()).isFalse();

        StreakStatus evening = StreakStatus.compute(days, TODAY.atTime(20, 30));
        assertThat(evening.atRisk()).isTrue();
    }

    @Test
    void streakBreaksAfterAMissedDay() {
        Set<LocalDate> days = lastDays(TODAY.minusDays(2), 5);
        StreakStatus s = StreakStatus.compute(days, TODAY.atTime(12, 0));
        assertThat(s.currentDays()).isZero();
        assertThat(s.bestDays()).isEqualTo(5);
        assertThat(s.atRisk()).isFalse();
    }

    @Test
    void streakMilestonesAndProgress() {
        StreakStatus s = StreakStatus.compute(lastDays(TODAY, 10), LocalDateTime.of(TODAY, java.time.LocalTime.NOON));
        assertThat(s.currentDays()).isEqualTo(10);
        assertThat(s.activeToday()).isTrue();
        assertThat(s.reachedMilestones()).containsExactly(7);
        assertThat(s.nextMilestone()).isEqualTo(30);
        assertThat(s.daysToNextMilestone()).isEqualTo(20);
        assertThat(s.milestoneProgress()).isCloseTo(3.0 / 23.0, org.assertj.core.data.Offset.offset(1e-9));

        StreakStatus legend = StreakStatus.compute(lastDays(TODAY, 400), TODAY.atTime(12, 0));
        assertThat(legend.nextMilestone()).isNull();
        assertThat(legend.reachedMilestones()).containsExactly(7, 30, 100, 365);
        assertThat(legend.milestoneProgress()).isEqualTo(1.0);
    }

    @Test
    void longestRunFindsHistoricalRecord() {
        Set<LocalDate> days = new java.util.HashSet<>(lastDays(TODAY.minusDays(30), 12));
        days.addAll(lastDays(TODAY, 2));
        assertThat(ActivityDays.longestRun(days)).isEqualTo(12);
        assertThat(ActivityDays.currentRun(days, TODAY)).isEqualTo(2);
    }

    // ---------------------------------------------------------------- criterios

    @Test
    void metricsCoverEveryCriterion() {
        BadgeActivitySnapshot snapshot = new BadgeActivitySnapshot(12, 5, Set.of(), lastDays(TODAY.minusDays(1), 7),
                21, 3, 10, 5, 11, 1, List.of());
        Map<BadgeCriterion, Integer> m = BadgeMetrics.compute(snapshot, 9, 4, TODAY);

        assertThat(m).containsEntry(BadgeCriterion.SESSIONS_COMPLETED, 12)
                .containsEntry(BadgeCriterion.HIGH_RPE_SESSIONS, 5)
                .containsEntry(BadgeCriterion.CONSECUTIVE_CHECK_INS, 7)
                .containsEntry(BadgeCriterion.STUDY_BLOCKS, 21)
                .containsEntry(BadgeCriterion.STUDY_PLANS, 3)
                .containsEntry(BadgeCriterion.NOTES_CREATED, 10)
                .containsEntry(BadgeCriterion.FEED_POSTS, 5)
                .containsEntry(BadgeCriterion.LIKES_RECEIVED, 11)
                .containsEntry(BadgeCriterion.STREAK_DAYS, 9)
                .containsEntry(BadgeCriterion.CHALLENGES_COMPLETED, 1)
                .containsEntry(BadgeCriterion.BADGES_EARNED, 4)
                .containsEntry(BadgeCriterion.PLAN_ADHERENCE_WEEKS, 0);
        assertThat(m).hasSize(BadgeCriterion.values().length - 1);
    }

    @Test
    void adherenceCountsConsecutiveWeeksAtEightyPercent() {
        LocalDate monday = LocalDate.parse("2026-10-12");
        List<WeeklyStudyLoad> loads = List.of(
                new WeeklyStudyLoad(monday, 10, 2),                 // semana en curso: no rompe
                new WeeklyStudyLoad(monday.minusWeeks(1), 10, 8),
                new WeeklyStudyLoad(monday.minusWeeks(2), 10, 9),
                new WeeklyStudyLoad(monday.minusWeeks(3), 5, 5),
                new WeeklyStudyLoad(monday.minusWeeks(4), 10, 10),
                new WeeklyStudyLoad(monday.minusWeeks(5), 10, 1));
        assertThat(BadgeMetrics.adherentWeeks(loads, TODAY)).isEqualTo(4);
    }

    @Test
    void adherenceBreaksOnGapsAndFailedWeeks() {
        LocalDate monday = LocalDate.parse("2026-10-05");
        assertThat(BadgeMetrics.adherentWeeks(List.of(
                new WeeklyStudyLoad(monday, 10, 9),
                new WeeklyStudyLoad(monday.minusWeeks(2), 10, 9)), TODAY)).isEqualTo(1);
        assertThat(BadgeMetrics.adherentWeeks(List.of(
                new WeeklyStudyLoad(monday, 10, 7),
                new WeeklyStudyLoad(monday.minusWeeks(1), 10, 9)), TODAY)).isZero();
    }

    @Test
    void badgeIsMetWhenMetricReachesValue() {
        Badge b = new Badge(java.util.UUID.randomUUID(), "Racha de fuego", "d", "🔥", BadgeCategory.STREAK,
                BadgeCriterion.STREAK_DAYS, 7, BadgeRarity.COMMON, 1);
        assertThat(b.isMetBy(Map.of(BadgeCriterion.STREAK_DAYS, 6))).isFalse();
        assertThat(b.isMetBy(Map.of(BadgeCriterion.STREAK_DAYS, 7))).isTrue();
        Badge unknown = new Badge(java.util.UUID.randomUUID(), "X", "d", "?", BadgeCategory.SPECIAL,
                BadgeCriterion.fromCode("desconocido"), 0, BadgeRarity.COMMON, 1);
        assertThat(unknown.isMetBy(Map.of())).isFalse();
    }
}
