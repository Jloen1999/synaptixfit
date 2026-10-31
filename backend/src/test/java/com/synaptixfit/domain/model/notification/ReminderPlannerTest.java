package com.synaptixfit.domain.model.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/** Reglas del plan de recordatorios (casos portados del antiguo {@code reminder_planner_test.dart}). */
class ReminderPlannerTest {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    // Miércoles 21/10/2026 a las 10:00 en Madrid.
    private static final Instant NOW = at(2026, 10, 21, 10, 0);
    private static final UUID USER = UUID.randomUUID();

    private final ReminderPlanner planner = new ReminderPlanner();

    private static Instant at(int y, int m, int d, int h, int min) {
        return LocalDateTime.of(y, m, d, h, min).atZone(ZONE).toInstant();
    }

    private static NotificationPreferences prefs(Set<NotificationType> categories, LocalTime quietStart,
                                                 LocalTime quietEnd, int limit, NotificationMode mode) {
        return new NotificationPreferences(UUID.randomUUID(), USER, categories, quietStart, quietEnd, limit, mode,
                NOW, NOW);
    }

    private static NotificationPreferences allOn() {
        return prefs(EnumSet.allOf(NotificationType.class), null, null, 20, NotificationMode.NORMAL);
    }

    private static NotificationPreferences quiet(int fromHour, int fromMinute, int toHour, int toMinute) {
        return prefs(EnumSet.allOf(NotificationType.class), LocalTime.of(fromHour, fromMinute),
                LocalTime.of(toHour, toMinute), 20, NotificationMode.NORMAL);
    }

    private static ReminderPlanner.Block block(String id, Instant start, ActivityType type) {
        return block(id, start, type, "Cuerpo completo A", false);
    }

    private static ReminderPlanner.Block block(String id, Instant start, ActivityType type, String title,
                                               boolean completed) {
        return new ReminderPlanner.Block(UUID.nameUUIDFromBytes(id.getBytes()), type, start, title, completed);
    }

    private List<ReminderPlan.Item> plan(int reviews, List<ReminderPlanner.Block> blocks,
                                         NotificationPreferences preferences, UsageFocus focus, Instant now) {
        return planner.plan(new ReminderPlanner.Input(reviews, blocks, preferences, focus, now, ZONE, 7)).reminders();
    }

    private List<ReminderPlan.Item> plan(int reviews, List<ReminderPlanner.Block> blocks) {
        return plan(reviews, blocks, allOn(), UsageFocus.BOTH, NOW);
    }

    @Test
    void remindsAtSevenPmTodayAndTheNextTwoDays() {
        List<ReminderPlan.Item> reminders = plan(3, List.of());

        assertThat(reminders).extracting(ReminderPlan.Item::at)
                .containsExactly(at(2026, 10, 21, 19, 0), at(2026, 10, 22, 19, 0), at(2026, 10, 23, 19, 0));
        assertThat(reminders).allSatisfy(r -> {
            assertThat(r.kind()).isEqualTo(ReminderKind.REVIEWS);
            assertThat(r.count()).isEqualTo(3);
        });
        assertThat(reminders).extracting(ReminderPlan.Item::refId)
                .containsExactly("2026-10-21", "2026-10-22", "2026-10-23");
    }

    @Test
    void afterSevenPmStartsTomorrow() {
        List<ReminderPlan.Item> reminders = plan(3, List.of(), allOn(), UsageFocus.BOTH,
                at(2026, 10, 21, 20, 0));

        assertThat(reminders).hasSize(3);
        assertThat(reminders.getFirst().at()).isEqualTo(at(2026, 10, 22, 19, 0));
    }

    @Test
    void noDueReviewsNoReminder() {
        assertThat(plan(0, List.of())).isEmpty();
    }

    @Test
    void quietHoursDelayItToTheirEnd() {
        List<ReminderPlan.Item> reminders = plan(3, List.of(), quiet(18, 0, 20, 30), UsageFocus.BOTH, NOW);

        assertThat(reminders.getFirst().at()).isEqualTo(at(2026, 10, 21, 20, 30));
    }

    @Test
    void quietHoursCrossingMidnightMoveItToTheMorning() {
        List<ReminderPlan.Item> reminders = plan(3, List.of(), quiet(18, 0, 8, 0), UsageFocus.BOTH, NOW);

        assertThat(reminders.getFirst().at()).isEqualTo(at(2026, 10, 22, 8, 0));
    }

    @Test
    void remindsFifteenMinutesBeforeASportBlock() {
        Instant start = at(2026, 10, 22, 13, 0);
        List<ReminderPlan.Item> reminders = plan(0, List.of(block("b1", start, ActivityType.SPORT)));

        assertThat(reminders).singleElement().satisfies(r -> {
            assertThat(r.kind()).isEqualTo(ReminderKind.TRAINING);
            assertThat(r.at()).isEqualTo(at(2026, 10, 22, 12, 45));
            assertThat(r.startsAt()).isEqualTo(start);
            assertThat(r.title()).isEqualTo("Cuerpo completo A");
            assertThat(r.refId()).isEqualTo(UUID.nameUUIDFromBytes("b1".getBytes()).toString());
            assertThat(r.count()).isNull();
        });
    }

    @Test
    void studyAndReviewBlocksRemindAsStudy() {
        List<ReminderPlan.Item> reminders = plan(0, List.of(
                block("s1", at(2026, 10, 22, 9, 0), ActivityType.STUDY),
                block("r1", at(2026, 10, 22, 11, 0), ActivityType.REVIEW)));

        assertThat(reminders).extracting(ReminderPlan.Item::kind)
                .containsExactly(ReminderKind.STUDY, ReminderKind.STUDY);
    }

    @Test
    void skipsStartedImminentCompletedFarAndOtherTypes() {
        List<ReminderPlan.Item> reminders = plan(0, List.of(
                block("past", at(2026, 10, 21, 9, 0), ActivityType.SPORT),
                // Empieza en 10 min: su aviso (9:55) ya pasó.
                block("soon", at(2026, 10, 21, 10, 10), ActivityType.SPORT),
                block("done", at(2026, 10, 22, 13, 0), ActivityType.SPORT, "Hecho", true),
                block("far", at(2026, 10, 29, 13, 0), ActivityType.SPORT),
                block("class", at(2026, 10, 22, 9, 0), ActivityType.CLASS),
                block("delivery", at(2026, 10, 22, 9, 0), ActivityType.DELIVERY),
                block("exam", at(2026, 10, 22, 9, 0), ActivityType.EXAM)));

        assertThat(reminders).isEmpty();
    }

    @Test
    void keepsAMissingTitleEmpty() {
        List<ReminderPlan.Item> reminders = plan(0, List.of(
                block("b1", at(2026, 10, 22, 13, 0), ActivityType.SPORT, null, false)));

        assertThat(reminders.getFirst().title()).isNull();
    }

    @Test
    void quietHoursDelayTheReminderOnlyIfItStillArrivesBeforeTheBlock() {
        List<ReminderPlan.Item> reminders = plan(0, List.of(
                block("ok", at(2026, 10, 22, 8, 5), ActivityType.SPORT),
                block("late", at(2026, 10, 22, 7, 30), ActivityType.SPORT)),
                quiet(22, 0, 8, 0), UsageFocus.BOTH, NOW);

        assertThat(reminders).singleElement()
                .satisfies(r -> assertThat(r.at()).isEqualTo(at(2026, 10, 22, 8, 0)));
    }

    @Test
    void respectsTheLocalZoneAcrossTheDaylightSavingChange() {
        // El 25/10/2026 Madrid pasa de UTC+2 a UTC+1: el aviso sigue siendo 15 min antes en hora local.
        List<ReminderPlan.Item> reminders = plan(0, List.of(
                block("dst", at(2026, 10, 26, 18, 0), ActivityType.SPORT)));

        assertThat(reminders.getFirst().at()).isEqualTo(Instant.parse("2026-10-26T16:45:00Z"));
    }

    private Set<ReminderKind> kinds(UsageFocus focus, NotificationPreferences preferences) {
        return plan(3, List.of(
                block("sport", at(2026, 10, 22, 13, 0), ActivityType.SPORT),
                block("study", at(2026, 10, 22, 9, 0), ActivityType.STUDY)), preferences, focus, NOW)
                .stream().map(ReminderPlan.Item::kind).collect(Collectors.toSet());
    }

    @Test
    void bothGivesReviewsStudyAndTraining() {
        // Sin entregas en el plan: los tres tipos de bloques y repasos.
        assertThat(kinds(UsageFocus.BOTH, allOn())).containsExactlyInAnyOrder(ReminderKind.REVIEWS,
                ReminderKind.STUDY, ReminderKind.TRAINING);
    }

    @Test
    void academicOnlyHasNoTraining() {
        assertThat(kinds(UsageFocus.ACADEMIC, allOn()))
                .containsExactlyInAnyOrder(ReminderKind.REVIEWS, ReminderKind.STUDY);
    }

    @Test
    void fitnessOnlyHasNoReviewsNorStudy() {
        assertThat(kinds(UsageFocus.FITNESS, allOn())).containsExactly(ReminderKind.TRAINING);
    }

    @Test
    void academicCategoryOffLeavesOnlyTraining() {
        NotificationPreferences milestoneOnly = prefs(Set.of(ReminderPlanner.TRAINING_CATEGORY), null, null, 20,
                NotificationMode.NORMAL);
        assertThat(kinds(UsageFocus.BOTH, milestoneOnly)).containsExactly(ReminderKind.TRAINING);
    }

    @Test
    void examModeKeepsOnlyAcademic() {
        NotificationPreferences exams = prefs(EnumSet.allOf(NotificationType.class), null, null, 20,
                NotificationMode.EXAMS);
        assertThat(kinds(UsageFocus.BOTH, exams))
                .containsExactlyInAnyOrder(ReminderKind.REVIEWS, ReminderKind.STUDY);
    }

    @Test
    void restModeGivesNothing() {
        NotificationPreferences rest = prefs(EnumSet.allOf(NotificationType.class), null, null, 20,
                NotificationMode.REST);
        assertThat(kinds(UsageFocus.BOTH, rest)).isEmpty();
    }

    @Test
    void wantsFlagsAvoidReadingUselessData() {
        NotificationPreferences rest = prefs(EnumSet.allOf(NotificationType.class), null, null, 20,
                NotificationMode.REST);
        assertThat(ReminderPlanner.wantsReviews(allOn(), UsageFocus.FITNESS)).isFalse();
        assertThat(ReminderPlanner.wantsBlocks(allOn(), UsageFocus.FITNESS)).isTrue();
        assertThat(ReminderPlanner.wantsBlocks(rest, UsageFocus.BOTH)).isFalse();
    }

    @Test
    void dailyLimitKeepsTheEarliestOfEachLocalDay() {
        NotificationPreferences two = prefs(EnumSet.allOf(NotificationType.class), null, null, 2,
                NotificationMode.NORMAL);
        List<ReminderPlan.Item> reminders = plan(3, List.of(
                block("a", at(2026, 10, 21, 12, 0), ActivityType.SPORT),
                block("b", at(2026, 10, 21, 14, 0), ActivityType.SPORT),
                block("c", at(2026, 10, 21, 16, 0), ActivityType.SPORT)), two, UsageFocus.BOTH, NOW);

        assertThat(reminders.stream().filter(r -> day(r).equals(LocalDate.of(2026, 10, 21))))
                .extracting(ReminderPlan.Item::at)
                .containsExactly(at(2026, 10, 21, 11, 45), at(2026, 10, 21, 13, 45));
        // Los repasos de los días siguientes no cuentan para hoy.
        assertThat(reminders.stream().filter(r -> day(r).equals(LocalDate.of(2026, 10, 22)))).hasSize(1);
    }

    @Test
    void dailyLimitZeroGivesNothing() {
        NotificationPreferences none = prefs(EnumSet.allOf(NotificationType.class), null, null, 0,
                NotificationMode.NORMAL);
        assertThat(plan(3, List.of(), none, UsageFocus.BOTH, NOW)).isEmpty();
        assertThat(ReminderPlanner.wantsReviews(none, UsageFocus.BOTH)).isFalse();
    }

    @Test
    void neverExceedsTheTotalCap() {
        ReminderPlan plan = new ReminderPlanner(2).plan(new ReminderPlanner.Input(3, List.of(), allOn(),
                UsageFocus.BOTH, NOW, ZONE, 7));

        assertThat(plan.reminders()).hasSize(2);
    }

    @Test
    void aShorterWindowDropsLaterReminders() {
        ReminderPlan plan = planner.plan(new ReminderPlanner.Input(3, List.of(), allOn(), UsageFocus.BOTH, NOW,
                ZONE, 1));

        assertThat(plan.reminders()).extracting(ReminderPlan.Item::at)
                .containsExactly(at(2026, 10, 21, 19, 0));
    }

    @Test
    void windowOutsideOneToSevenDaysIsInvalid() {
        Arrays.asList(0, 8).forEach(days -> assertThatThrownBy(() -> planner.plan(new ReminderPlanner.Input(0,
                List.of(), allOn(), UsageFocus.BOTH, NOW, ZONE, days)))
                .isInstanceOf(FieldValidationException.class));
    }

    private LocalDate day(ReminderPlan.Item item) {
        return item.at().atZone(ZONE).toLocalDate();
    }
}
