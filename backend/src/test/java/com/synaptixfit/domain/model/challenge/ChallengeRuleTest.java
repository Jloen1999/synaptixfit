package com.synaptixfit.domain.model.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Retos que se cuentan solos (ADR 0043): qué cuenta cada regla y cómo se completa o se deshace el reto. */
class ChallengeRuleTest {

    private static final ZoneId MADRID = ZoneId.of("Europe/Madrid");
    /** Lunes 2 de noviembre de 2026, 9:00 en Madrid. */
    private static final ZonedDateTime MONDAY = ZonedDateTime.of(2026, 11, 2, 9, 0, 0, 0, MADRID);
    private static final Instant START = MONDAY.toInstant();
    private static final Instant END = MONDAY.plusDays(13).withHour(23).withMinute(59).toInstant();

    private static Instant on(int dayOffset, int hour) {
        return MONDAY.plusDays(dayOffset).withHour(hour).toInstant();
    }

    @Test
    void dailyRuleCountsDaysThatReachTheMinimum() {
        ChallengeRule rule = new ChallengeRule(RuleMetric.FOCUS_MINUTES, RuleUnit.DAY, 25, 5, false);
        List<ActivityFact> facts = List.of(
                ActivityFact.at(ActivityKind.FOCUS, on(0, 11), 25),
                ActivityFact.at(ActivityKind.FOCUS, on(1, 11), 15),
                ActivityFact.at(ActivityKind.FOCUS, on(1, 18), 15),
                ActivityFact.at(ActivityKind.FOCUS, on(2, 11), 20));

        // Lunes (25) y martes (15 + 15) llegan; el miércoles (20) no.
        assertThat(rule.count(facts, START, END, MADRID)).isEqualTo(2);
    }

    @Test
    void onlyWhatHappensInsideTheChallengeCountsAndNeverAboveTheTarget() {
        ChallengeRule rule = new ChallengeRule(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 2, false);
        List<ActivityFact> facts = List.of(
                ActivityFact.at(ActivityKind.REVIEW, START.minusSeconds(60), 1),
                ActivityFact.at(ActivityKind.REVIEW, on(0, 12), 1),
                ActivityFact.at(ActivityKind.REVIEW, on(1, 12), 1),
                ActivityFact.at(ActivityKind.REVIEW, on(2, 12), 1),
                ActivityFact.at(ActivityKind.FOCUS, on(3, 12), 30),
                ActivityFact.at(ActivityKind.REVIEW, END.plusSeconds(60), 1));

        assertThat(rule.count(facts, START, END, MADRID)).isEqualTo(2);
    }

    @Test
    void weeklyRuleCountsMondayToSundayWeeks() {
        ChallengeRule rule = new ChallengeRule(RuleMetric.WORKOUTS, RuleUnit.WEEK, 3, 3, false);
        List<ActivityFact> facts = List.of(
                ActivityFact.at(ActivityKind.WORKOUT, on(0, 18), 1),
                ActivityFact.at(ActivityKind.WORKOUT, on(2, 18), 1),
                ActivityFact.at(ActivityKind.WORKOUT, on(6, 18), 1),
                ActivityFact.at(ActivityKind.WORKOUT, on(7, 18), 1),
                ActivityFact.at(ActivityKind.WORKOUT, on(8, 18), 1));

        // Semana 1: lunes, miércoles y domingo (3). Semana 2: lunes y martes (2).
        assertThat(rule.count(facts, START, END, MADRID)).isEqualTo(1);
    }

    @Test
    void earlyFocusCountsPomodorosStartedBefore10OnWeekdays() {
        ChallengeRule rule = new ChallengeRule(RuleMetric.EARLY_FOCUS, RuleUnit.DAY, 1, 8, true);
        List<ActivityFact> facts = List.of(
                // Termina a las 10:10 tras 25 min: empezó a las 9:45.
                ActivityFact.at(ActivityKind.FOCUS, MONDAY.withHour(10).withMinute(10).toInstant(), 25),
                // Termina a las 10:30 tras 25 min: empezó a las 10:05.
                ActivityFact.at(ActivityKind.FOCUS, MONDAY.plusDays(1).withHour(10).withMinute(30).toInstant(), 25),
                // Sábado temprano: no es laborable.
                ActivityFact.at(ActivityKind.FOCUS, on(5, 9), 25));

        assertThat(rule.count(facts, START, END, MADRID)).isEqualTo(1);
    }

    @Test
    void studyAndMoveNeedsBothOnTheSameDay() {
        ChallengeRule rule = new ChallengeRule(RuleMetric.STUDY_AND_MOVE, RuleUnit.DAY, 1, 5, false);
        List<ActivityFact> facts = List.of(
                ActivityFact.at(ActivityKind.FOCUS, on(0, 11), 25),
                ActivityFact.at(ActivityKind.WORKOUT, on(0, 19), 1),
                ActivityFact.at(ActivityKind.FOCUS, on(1, 11), 25),
                ActivityFact.at(ActivityKind.WORKOUT, on(2, 19), 1));

        assertThat(rule.count(facts, START, END, MADRID)).isEqualTo(1);
    }

    @Test
    void totalRuleAddsUpAndDateOnlyFactsUseTheirDay() {
        ChallengeRule minutes = new ChallengeRule(RuleMetric.FOCUS_MINUTES, RuleUnit.TOTAL, 1, 600, false);
        assertThat(minutes.count(List.of(ActivityFact.at(ActivityKind.FOCUS, on(0, 11), 50),
                ActivityFact.at(ActivityKind.FOCUS, on(3, 11), 25)), START, END, MADRID)).isEqualTo(75);

        ChallengeRule checkIns = new ChallengeRule(RuleMetric.CHECK_INS, RuleUnit.DAY, 1, 18, false);
        List<ActivityFact> days = List.of(
                new ActivityFact(ActivityKind.CHECK_IN, null, LocalDate.of(2026, 11, 1), 1),
                new ActivityFact(ActivityKind.CHECK_IN, null, LocalDate.of(2026, 11, 2), 1),
                new ActivityFact(ActivityKind.CHECK_IN, null, LocalDate.of(2026, 11, 3), 1));
        assertThat(checkIns.count(days, START, END, MADRID)).isEqualTo(2);
        assertThat(checkIns.privateOnly()).isTrue();
    }

    @Test
    void plannedWeeksCountByTheirMondayWhenPlannedInsideTheChallenge() {
        ChallengeRule rule = new ChallengeRule(RuleMetric.PLANNED_WEEKS, RuleUnit.WEEK, 1, 4, false);
        List<ActivityFact> facts = List.of(
                new ActivityFact(ActivityKind.PLANNED_WEEK, on(0, 20), LocalDate.of(2026, 11, 2), 1),
                new ActivityFact(ActivityKind.PLANNED_WEEK, on(6, 20), LocalDate.of(2026, 11, 9), 1),
                new ActivityFact(ActivityKind.PLANNED_WEEK, START.minusSeconds(3600), LocalDate.of(2026, 10, 26), 1));

        assertThat(rule.count(facts, START, END, MADRID)).isEqualTo(2);
    }

    @Test
    void availabilityFollowsTheUsageFocus() {
        ChallengeRule studyAndMove = new ChallengeRule(RuleMetric.STUDY_AND_MOVE, RuleUnit.DAY, 1, 5, false);
        assertThat(studyAndMove.availableFor(UsageFocus.BOTH)).isTrue();
        assertThat(studyAndMove.availableFor(UsageFocus.ACADEMIC)).isFalse();
        assertThat(new ChallengeRule(RuleMetric.PLANNED_WEEKS, RuleUnit.WEEK, 1, 4, false)
                .availableFor(UsageFocus.FITNESS)).isTrue();
    }

    private static Challenge fromTemplate(ChallengeRule rule, Visibility visibility) {
        ChallengeDetails details = new ChallengeDetails("Repasa cada día", ChallengeType.ACADEMIC, null, visibility,
                Difficulty.MEDIUM, START, END, null, null);
        return Challenge.fromTemplate(UUID.randomUUID(), UUID.randomUUID(), details, rule, "repasa_cada_dia", START);
    }

    @Test
    void reachingTheTargetCompletesWithXpAndDroppingBelowUndoesIt() {
        Challenge c = fromTemplate(new ChallengeRule(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 3, false),
                Visibility.PUBLIC);
        LocalDate today = LocalDate.of(2026, 11, 5);

        assertThat(c.applyRule(2, today).xpDelta()).isZero();
        assertThat(c.progress()).isEqualTo(66.67);
        ChallengeChanges done = c.applyRule(3, today);
        assertThat(c.completed()).isTrue();
        assertThat(done.xpDelta()).isEqualTo(Difficulty.MEDIUM.xp());
        assertThat(done.challengeCompleted()).isTrue();

        ChallengeChanges undone = c.applyRule(2, today);
        assertThat(c.completed()).isFalse();
        assertThat(undone.xpDelta()).isEqualTo(-Difficulty.MEDIUM.xp());
    }

    @Test
    void completingByHandBeforeTheTargetGivesNoXpUntilTheRuleArrives() {
        Challenge c = fromTemplate(new ChallengeRule(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 3, false),
                Visibility.PRIVATE);
        LocalDate today = LocalDate.of(2026, 11, 5);

        assertThat(c.complete(today).xpDelta()).isZero();
        assertThat(c.applyRule(3, today).xpDelta()).isEqualTo(Difficulty.MEDIUM.xp());
    }

    @Test
    void aWellbeingChallengeIsAlwaysPrivateAndARuleHasNoSessionTarget() {
        Challenge c = fromTemplate(new ChallengeRule(RuleMetric.CHECK_INS, RuleUnit.DAY, 1, 18, false),
                Visibility.PUBLIC);
        assertThat(c.visibility()).isEqualTo(Visibility.PRIVATE);

        c.updateDetails(new ChallengeDetails(c.title(), ChallengeType.FITNESS, null, Visibility.PUBLIC,
                Difficulty.MEDIUM, START, END, null, null));
        assertThat(c.visibility()).isEqualTo(Visibility.PRIVATE);

        assertThatThrownBy(() -> c.updateDetails(new ChallengeDetails(c.title(), ChallengeType.FITNESS, null, null,
                Difficulty.MEDIUM, START, END, null, null, 5))).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void templateChallengeEndsAtTheEndOfItsLastDay() {
        ChallengeTemplate t = new ChallengeTemplate(UUID.randomUUID(), "repasa_cada_dia", ChallengeType.ACADEMIC,
                Difficulty.MEDIUM, 14, new ChallengeRule(RuleMetric.REVIEWS, RuleUnit.DAY, 1, 12, false),
                "Repasa cada día", "Un repaso al día");

        ChallengeDetails d = t.detailsFrom(START, MADRID);

        assertThat(d.startAt()).isEqualTo(START);
        assertThat(d.endAt()).isEqualTo(MONDAY.plusDays(14).toLocalDate().atStartOfDay(MADRID).toInstant()
                .minusSeconds(1));
        assertThat(d.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(t.availableFor(UsageFocus.FITNESS)).isFalse();
    }
}
