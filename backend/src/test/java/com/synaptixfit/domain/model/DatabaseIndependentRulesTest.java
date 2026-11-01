package com.synaptixfit.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.admin.AdminActivityAggregation;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyInterval;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.StudyWeek;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserActivity;
import com.synaptixfit.domain.model.admin.AdminActivityAggregation.UserFocus;
import com.synaptixfit.domain.model.admin.DailyActivityPoint;
import com.synaptixfit.domain.model.admin.WeeklyActivityPoint;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric;
import com.synaptixfit.domain.model.analytics.WeeklyTrainingMetric.CompletedSession;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.challenge.Challenge;
import com.synaptixfit.domain.model.challenge.ChallengeStatus;
import com.synaptixfit.domain.model.challenge.ChallengeSummary;
import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.insights.DailyLoad;
import com.synaptixfit.domain.model.insights.PhysicalLoadHistory;
import com.synaptixfit.domain.model.insights.PracticeSessions;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.PostType;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Reglas que antes calculaba la base de datos (vistas, columnas generadas, FILTER, NOT EXISTS…) y
 * ahora viven en el dominio para que cambiar de motor no cambie el comportamiento (ADR 0012).
 */
class DatabaseIndependentRulesTest {

    private static final UUID ANA = UUID.randomUUID();
    private static final UUID LUIS = UUID.randomUUID();
    private static final LocalDate MONDAY = LocalDate.of(2026, 10, 12);

    // ------------------------------------------------------------ carga física (antes carga_diaria GENERATED)

    @Test
    void physicalLoadIsRpeTimesMinutesSummedPerDay() {
        List<PhysicalLoadHistory.Entry> entries = List.of(
                new PhysicalLoadHistory.Entry(MONDAY.plusDays(1), 6, 30),
                new PhysicalLoadHistory.Entry(MONDAY, 5, 60),
                new PhysicalLoadHistory.Entry(MONDAY, 8, 20));

        assertThat(PhysicalLoadHistory.dailyLoads(entries)).containsExactly(
                new DailyLoad(MONDAY, 460), new DailyLoad(MONDAY.plusDays(1), 180));
        assertThat(PhysicalLoadHistory.total(entries)).isEqualTo(640);
        assertThat(PhysicalLoadHistory.total(entries, MONDAY, MONDAY)).isEqualTo(460);
        assertThat(PhysicalLoadHistory.total(entries, MONDAY.plusDays(1), MONDAY.plusDays(7))).isEqualTo(180);
        assertThat(PhysicalLoadHistory.maxDailyLoad(entries)).isEqualTo(460);
        assertThat(PhysicalLoadHistory.maxDailyLoad(List.of())).isZero();
    }

    // ------------------------------------------------------------ analítica semanal (antes v_analitica_semanal)

    @Test
    void weeklyTrainingGroupsByUtcMondayAndAveragesOnlyKnownRpe() {
        List<CompletedSession> sessions = List.of(
                new CompletedSession(Instant.parse("2026-10-12T00:30:00Z"), 40, 300.4, 7),
                new CompletedSession(Instant.parse("2026-10-18T23:30:00Z"), 20, 100.3, 8), // domingo: misma semana
                new CompletedSession(Instant.parse("2026-10-15T10:00:00Z"), 30, null, null),
                new CompletedSession(Instant.parse("2026-10-19T00:10:00Z"), 50, 400.0, 6)); // lunes siguiente

        List<WeeklyTrainingMetric> weeks = WeeklyTrainingMetric.byWeek(sessions, java.time.ZoneOffset.UTC);

        assertThat(weeks).containsExactly(
                new WeeklyTrainingMetric(MONDAY, 3, 7.5, 90, 401),
                new WeeklyTrainingMetric(MONDAY.plusWeeks(1), 1, 6.0, 50, 400));
    }

    @Test
    void weeklyRpeIsNullWithoutRatingsAndRoundedToOneDecimal() {
        assertThat(WeeklyTrainingMetric.byWeek(List.of(
                new CompletedSession(Instant.parse("2026-10-13T10:00:00Z"), 30, null, null)), java.time.ZoneOffset.UTC).getFirst().averageRpe())
                .isNull();
        assertThat(WeeklyTrainingMetric.byWeek(List.of(
                new CompletedSession(Instant.parse("2026-10-13T10:00:00Z"), 30, null, 7),
                new CompletedSession(Instant.parse("2026-10-13T11:00:00Z"), 30, null, 8),
                new CompletedSession(Instant.parse("2026-10-13T12:00:00Z"), 30, null, 8)), java.time.ZoneOffset.UTC).getFirst().averageRpe())
                .isEqualTo(7.7);
    }

    // ------------------------------------------------------------ panel de administración (antes v_admin_metricas)

    @Test
    void dailyActivityFillsEmptyDaysAndCountsEachActiveUserOnce() {
        LocalDate day1 = LocalDate.of(2026, 10, 14);
        LocalDate day3 = day1.plusDays(2);
        List<DailyActivityPoint> points = AdminActivityAggregation.daily(day1, day3,
                List.of(Instant.parse("2026-10-14T08:00:00Z"), Instant.parse("2026-10-16T23:59:00Z")),
                List.of(new UserActivity(ANA, Instant.parse("2026-10-14T09:00:00Z")),
                        new UserActivity(ANA, Instant.parse("2026-10-14T18:00:00Z"))),
                List.of(new UserActivity(ANA, Instant.parse("2026-10-14T11:00:00Z")),
                        new UserActivity(LUIS, Instant.parse("2026-10-16T07:00:00Z"))),
                List.of(new UserFocus(LUIS, day1, 25)));

        assertThat(points).containsExactly(
                new DailyActivityPoint(day1, 1, 2, 2),
                new DailyActivityPoint(day1.plusDays(1), 0, 0, 0),
                new DailyActivityPoint(day3, 1, 1, 0));
    }

    @Test
    void weeklyActivityCombinesTrainingStudyAndFocusPerWeek() {
        List<WeeklyActivityPoint> weeks = AdminActivityAggregation.weekly(MONDAY, MONDAY.plusWeeks(1),
                List.of(new CompletedSession(Instant.parse("2026-10-13T10:00:00Z"), 45, 320.6, 6)),
                List.of(new StudyInterval(Instant.parse("2026-10-14T09:00:00Z"), Instant.parse("2026-10-14T09:50:30Z")),
                        new StudyInterval(Instant.parse("2026-10-20T09:00:00Z"), Instant.parse("2026-10-20T10:00:00Z"))),
                List.of(new UserFocus(ANA, MONDAY.plusDays(8), 25), new UserFocus(ANA, MONDAY.plusDays(9), 25)));

        assertThat(weeks).containsExactly(
                new WeeklyActivityPoint(MONDAY, 1, 45, 321, 6.0, 51, 0),
                new WeeklyActivityPoint(MONDAY.plusWeeks(1), 0, 0, 0, null, 60, 50));
    }

    @Test
    void adherenceIsActualOverPlannedHoursAndNullWithoutPlan() {
        assertThat(AdminActivityAggregation.adherencePercent(List.of(new StudyWeek(10, 8), new StudyWeek(10, 7))))
                .isEqualTo(75);
        assertThat(AdminActivityAggregation.adherencePercent(List.of(new StudyWeek(0, 5)))).isNull();
        assertThat(AdminActivityAggregation.adherencePercent(List.of())).isNull();
        assertThat(AdminActivityAggregation.studyMinutes(List.of(
                new StudyInterval(Instant.parse("2026-10-14T09:00:00Z"), Instant.parse("2026-10-14T09:30:40Z")),
                new StudyInterval(Instant.parse("2026-10-14T10:00:00Z"), Instant.parse("2026-10-14T10:20:00Z")))))
                .isEqualTo(51);
    }

    // ------------------------------------------------------------ retos (antes count(*) FILTER)

    @Test
    void challengeStatusRuleIsTheSameForTheSummary() {
        Instant now = Instant.parse("2026-10-14T12:00:00Z");
        Instant start = now.minusSeconds(3600);
        assertThat(Challenge.statusOf(true, start, now.minusSeconds(60), now)).isEqualTo(ChallengeStatus.COMPLETED);
        assertThat(Challenge.statusOf(false, start, now, now)).isEqualTo(ChallengeStatus.ACTIVE);
        assertThat(Challenge.statusOf(false, start, now.minusSeconds(1), now)).isEqualTo(ChallengeStatus.EXPIRED);
        assertThat(Challenge.statusOf(false, now.plusSeconds(60), now.plusSeconds(3600), now))
                .isEqualTo(ChallengeStatus.UPCOMING);
        // «active» cuenta los abiertos (en curso y por empezar) y «upcoming» desglosa los segundos.
        assertThat(ChallengeSummary.of(List.of(ChallengeStatus.ACTIVE, ChallengeStatus.EXPIRED, ChallengeStatus.ACTIVE,
                ChallengeStatus.COMPLETED, ChallengeStatus.UPCOMING))).isEqualTo(new ChallengeSummary(3, 1, 1, 1));
    }

    @Test
    void challengeVisibilityIsDecidedInTheDomainFromRawAudienceData() {
        AuthorAudience stranger = new AuthorAudience(true, false, Visibility.PUBLIC, false, false);
        AuthorAudience friend = new AuthorAudience(true, false, Visibility.PUBLIC, true, false);
        assertThat(challenge(Visibility.PUBLIC).isVisibleTo(stranger)).isTrue();
        assertThat(challenge(Visibility.FRIENDS).isVisibleTo(stranger)).isFalse();
        assertThat(challenge(Visibility.FRIENDS).isVisibleTo(friend)).isTrue();
        assertThat(challenge(Visibility.PRIVATE).isVisibleTo(friend)).isFalse();
        assertThat(challenge(Visibility.PUBLIC).isVisibleTo(new AuthorAudience(true, true, Visibility.PUBLIC, true, false))).isFalse();
        assertThat(challenge(Visibility.PUBLIC).isVisibleTo(new AuthorAudience(false, false, Visibility.PUBLIC, true, false))).isFalse();
    }

    private static Challenge challenge(Visibility visibility) {
        Instant now = Instant.parse("2026-10-14T12:00:00Z");
        return Challenge.builder().id(UUID.randomUUID()).ownerId(ANA).title("Correr 5 km").visibility(visibility)
                .startAt(now).endAt(now.plusSeconds(86400)).createdAt(now).build();
    }

    // ------------------------------------------------------------ prácticas sin bloque (antes NOT EXISTS)

    @Test
    void practicesInsideACompletedBlockAreNotCountedTwice() {
        UUID material = UUID.randomUUID();
        assertThat(PracticeSessions.focusCounts(false)).isTrue();
        assertThat(PracticeSessions.focusCounts(true)).isFalse();
        assertThat(PracticeSessions.reviewCounts(material, Set.of())).isTrue();
        assertThat(PracticeSessions.reviewCounts(material, Set.of(material))).isFalse();
    }

    // ------------------------------------------------------------ insignias (antes literales en el SQL)

    @Test
    void badgeThresholdsAreDomainConstants() {
        assertThat(BadgeActivitySnapshot.HIGH_RPE_MIN).isEqualTo(8);
        assertThat(BadgeActivitySnapshot.AUTOMATIC_POSTS)
                .containsExactlyInAnyOrder(PostType.CHALLENGE_COMPLETED, PostType.BADGE_UNLOCKED);
    }
}
