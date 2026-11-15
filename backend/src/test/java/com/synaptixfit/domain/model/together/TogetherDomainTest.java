package com.synaptixfit.domain.model.together;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.together.FriendChallengeTemplateNotAllowedException;
import com.synaptixfit.domain.exception.together.FriendStreakNudgeUnavailableException;
import com.synaptixfit.domain.exception.together.TogetherGroupSizeException;
import com.synaptixfit.domain.exception.together.TogetherInvalidStateException;
import com.synaptixfit.domain.model.challenge.ActivityFact;
import com.synaptixfit.domain.model.challenge.ActivityKind;
import com.synaptixfit.domain.model.challenge.ChallengeRule;
import com.synaptixfit.domain.model.challenge.ChallengeTemplate;
import com.synaptixfit.domain.model.challenge.ChallengeType;
import com.synaptixfit.domain.model.challenge.Difficulty;
import com.synaptixfit.domain.model.challenge.RuleMetric;
import com.synaptixfit.domain.model.challenge.RuleUnit;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.IntStream;
import org.junit.jupiter.api.Test;

/** Reglas de «Con amigos» (ADR 0044): metas, tope diario, racha compartida con pausas y personas. */
class TogetherDomainTest {

    private static final ZoneId UTC = ZoneOffset.UTC;
    private static final Instant NOW = Instant.parse("2026-11-16T09:00:00Z");

    private static ChallengeTemplate template(RuleMetric metric, RuleUnit unit, int perUnit, int target, int days) {
        return new ChallengeTemplate(UUID.randomUUID(), "t", ChallengeType.ACADEMIC, Difficulty.MEDIUM, days,
                new ChallengeRule(metric, unit, perUnit, target, false), "Título", "Meta");
    }

    @Test
    void personalTargetIsScaledToTheChallengeDays() {
        assertThat(FriendChallenge.perPersonTarget(template(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 12, 14), 7))
                .isEqualTo(6);
        assertThat(FriendChallenge.perPersonTarget(template(RuleMetric.FOCUS_MINUTES, RuleUnit.TOTAL, 1, 600, 14), 7))
                .isEqualTo(300);
        assertThat(FriendChallenge.perPersonTarget(template(RuleMetric.WORKOUTS, RuleUnit.WEEK, 3, 3, 21), 14))
                .isEqualTo(2);
        assertThat(FriendChallenge.perPersonTarget(template(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 5, 7), 14))
                .isEqualTo(10);
    }

    @Test
    void wellbeingTemplatesAndWrongGroupsAreRejected() {
        UUID me = UUID.randomUUID();
        Set<UUID> one = Set.of(UUID.randomUUID());
        assertThatThrownBy(() -> FriendChallenge.create(me, template(RuleMetric.CHECK_INS, RuleUnit.DAY, 1, 18, 21),
                one, null, 7, NOW, UTC)).isInstanceOf(FriendChallengeTemplateNotAllowedException.class);
        assertThatThrownBy(() -> FriendChallenge.create(me, template(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 12, 14),
                Set.of(me), null, 7, NOW, UTC)).isInstanceOf(TogetherGroupSizeException.class);
        Set<UUID> tooMany = new HashSet<>();
        IntStream.range(0, 25).forEach(i -> tooMany.add(UUID.randomUUID()));
        assertThatThrownBy(() -> FriendChallenge.create(me, template(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 12, 14),
                tooMany, null, 7, NOW, UTC)).isInstanceOf(TogetherGroupSizeException.class);
    }

    @Test
    void cooperativeByDefaultEndsAtTheLastDayAndTheGroupTargetFollowsWhoIsIn() {
        UUID me = UUID.randomUUID();
        UUID ana = UUID.randomUUID();
        UUID luis = UUID.randomUUID();
        FriendChallenge c = FriendChallenge.create(me, template(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 12, 14),
                Set.of(ana, luis), null, 7, NOW, UTC);
        assertThat(c.mode()).isEqualTo(FriendChallengeMode.COOPERATIVE);
        assertThat(c.endAt()).isEqualTo(Instant.parse("2026-11-22T23:59:59Z"));
        assertThat(c.groupTarget()).isEqualTo(6);
        c.join(ana, NOW);
        assertThat(c.groupTarget()).isEqualTo(12);
        assertThat(c.leave(ana, NOW)).isTrue();
        assertThat(c.canView(ana)).isFalse();
        c.join(ana, NOW);
        c.decline(luis, NOW);
        assertThatThrownBy(() -> c.decline(luis, NOW)).isInstanceOf(TogetherInvalidStateException.class);
        assertThatThrownBy(() -> c.join(ana, Instant.parse("2026-11-23T00:00:00Z")))
                .isInstanceOf(TogetherInvalidStateException.class);
    }

    @Test
    void focusMinutesCountWithADailyCapAndDaysOnlyOnce() {
        Instant start = Instant.parse("2026-11-16T00:00:00Z");
        Instant end = Instant.parse("2026-11-22T23:59:59Z");
        List<ActivityFact> facts = List.of(
                ActivityFact.at(ActivityKind.FOCUS, Instant.parse("2026-11-16T10:00:00Z"), 100),
                ActivityFact.at(ActivityKind.FOCUS, Instant.parse("2026-11-16T12:00:00Z"), 100),
                ActivityFact.at(ActivityKind.FOCUS, Instant.parse("2026-11-17T12:00:00Z"), 25));
        ChallengeRule minutes = new ChallengeRule(RuleMetric.FOCUS_MINUTES, RuleUnit.TOTAL, 1, 600, false);
        assertThat(FriendChallengeScore.points(minutes, facts, start, end, UTC, 120)).isEqualTo(145);
        ChallengeRule daily = new ChallengeRule(RuleMetric.FOCUS_MINUTES, RuleUnit.DAY, 25, 5, false);
        assertThat(FriendChallengeScore.points(daily, facts, start, end, UTC, 1)).isEqualTo(2);
        assertThat(FriendChallengeScore.contributionDays(daily, facts, start, end, UTC))
                .containsExactly(LocalDate.parse("2026-11-17"), LocalDate.parse("2026-11-16"));
    }

    @Test
    void sharedStreakCountsBothDaysSkipsPausesAndBreaksOnAMiss() {
        LocalDate today = LocalDate.parse("2026-11-20");
        LocalDate since = LocalDate.parse("2026-11-14");
        Set<LocalDate> a = Set.of(today, today.minusDays(1), today.minusDays(3), today.minusDays(4),
                today.minusDays(6));
        Set<LocalDate> b = Set.of(today.minusDays(1), today.minusDays(3), today.minusDays(4), today.minusDays(6));
        // Hoy le falta a B: no suma ni rompe. Ayer los dos; anteayer, B en pausa; luego dos días de los dos; el día 5,
        // nadie y sin pausa: rompe.
        Set<LocalDate> pausedB = Set.of(today.minusDays(2));
        assertThat(FriendStreakCount.days(since, today, a, b, Set.of(), pausedB)).isEqualTo(3);
        assertThat(FriendStreakCount.days(since, today, a, b, Set.of(), Set.of())).isEqualTo(1);
        assertThat(FriendStreakCount.days(today.minusDays(1), today, a, b, Set.of(), pausedB)).isEqualTo(1);
        assertThat(FriendStreakCount.days(null, today, a, b, Set.of(), Set.of())).isZero();
    }

    @Test
    void nudgeOnlyOnceADayWhenIDidMineAndTheFriendDidNot() {
        UUID me = UUID.randomUUID();
        UUID ana = UUID.randomUUID();
        FriendStreak s = FriendStreak.propose(me, ana, NOW);
        assertThatThrownBy(() -> s.accept(me, LocalDate.parse("2026-11-16"), NOW))
                .isInstanceOf(TogetherInvalidStateException.class);
        s.accept(ana, LocalDate.parse("2026-11-16"), NOW);
        LocalDate today = LocalDate.parse("2026-11-17");
        assertThat(s.canNudge(today, false, false)).isFalse();
        assertThat(s.canNudge(today, true, true)).isFalse();
        s.nudge(today, true, false, NOW);
        assertThatThrownBy(() -> s.nudge(today, true, false, NOW))
                .isInstanceOf(FriendStreakNudgeUnavailableException.class);
        assertThat(s.canNudge(today.plusDays(1), true, false)).isTrue();
    }

    @Test
    void workoutTogetherIsOnlyForTodayAndNeedsJoiningBeforeStarting() {
        UUID host = UUID.randomUUID();
        UUID ana = UUID.randomUUID();
        LocalDate today = LocalDate.parse("2026-11-16");
        WorkoutTogether w = WorkoutTogether.create(host, UUID.randomUUID(), UUID.randomUUID(), Set.of(ana), today,
                NOW);
        assertThatThrownBy(() -> w.attachSession(ana, UUID.randomUUID(), today))
                .isInstanceOf(TogetherInvalidStateException.class);
        assertThatThrownBy(() -> w.join(ana, today.plusDays(1), NOW))
                .isInstanceOf(TogetherInvalidStateException.class);
        w.join(ana, today, NOW);
        UUID session = UUID.randomUUID();
        w.attachSession(ana, session, today);
        assertThat(w.sessionOf(ana)).contains(session);
        assertThatThrownBy(() -> WorkoutTogether.create(host, UUID.randomUUID(), UUID.randomUUID(),
                Set.of(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID()),
                today, NOW)).isInstanceOf(TogetherGroupSizeException.class);
    }
}
