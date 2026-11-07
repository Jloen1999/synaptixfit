package com.synaptixfit.domain.model.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.notification.ReminderOptionsInvalidException;
import com.synaptixfit.domain.model.challenge.DatedTask;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Reglas de avisos de ADR 0035: antelación elegida, eventos personales, tareas de reto sin duplicados y resumen de la
 * mañana (solo si hay algo y sin coincidir con el registro diario).
 */
class ReminderTasksAndSummaryTest {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    // Miércoles 21/10/2026 a las 10:00 en Madrid.
    private static final Instant NOW = at(21, 10, 0);
    private static final UUID USER = UUID.randomUUID();
    private static final UUID CHALLENGE = UUID.randomUUID();

    private final ReminderPlanner planner = new ReminderPlanner();

    private static Instant at(int day, int h, int min) {
        return LocalDateTime.of(2026, 10, day, h, min).atZone(ZONE).toInstant();
    }

    private static NotificationPreferences prefs(Set<NotificationType> categories) {
        return new NotificationPreferences(UUID.randomUUID(), USER, categories, null, null, 20,
                NotificationMode.NORMAL, NOW, NOW);
    }

    private static NotificationPreferences allOn() {
        return prefs(EnumSet.allOf(NotificationType.class));
    }

    private static ReminderOptions options(Integer lead, Set<Integer> days, ReminderOptions.TaskTiming timing,
                                           LocalTime summary, boolean summaryOff) {
        return ReminderOptions.DEFAULTS.with(new ReminderOptions.Change(null, null, null, lead, days, timing, summary,
                summaryOff ? Boolean.FALSE : null));
    }

    private static final ReminderOptions NO_SUMMARY = options(null, null, null, null, true);

    private static ReminderPlanner.Block block(UUID id, ActivityType type, Instant start) {
        return new ReminderPlanner.Block(id, type, start, "Tema 3", false);
    }

    private static DatedTask task(String title, DatedTask.Anchor anchor, UUID anchorId, Instant due) {
        return new DatedTask(CHALLENGE, "Aprobar Física", UUID.nameUUIDFromBytes(title.getBytes()), title, anchor,
                anchorId, due);
    }

    private List<ReminderPlan.Item> plan(List<ReminderPlanner.Block> blocks, List<ReminderPlanner.Deadline> deadlines,
                                         ReminderOptions options, List<DatedTask> tasks,
                                         List<ReminderPlan.Item> extra) {
        return planner.plan(new ReminderPlanner.Input(0, blocks, allOn(), UsageFocus.BOTH, NOW, ZONE, 7, deadlines,
                false, null, options, tasks), extra).reminders();
    }

    @Test
    void theChosenLeadTimeAppliesToEvents() {
        UUID id = UUID.randomUUID();
        List<ReminderPlan.Item> items = plan(List.of(block(id, ActivityType.STUDY, at(22, 18, 0))), List.of(),
                options(60, null, null, null, true), List.of(), List.of());

        assertThat(items).singleElement().satisfies(i -> assertThat(i.at()).isEqualTo(at(22, 17, 0)));
    }

    @Test
    void personalEventsAreRemindedEvenInExamMode() {
        UUID id = UUID.randomUUID();
        NotificationPreferences exams = new NotificationPreferences(UUID.randomUUID(), USER,
                EnumSet.allOf(NotificationType.class), null, null, 20, NotificationMode.EXAMS, NOW, NOW);
        List<ReminderPlan.Item> items = planner.plan(new ReminderPlanner.Input(0,
                List.of(block(id, ActivityType.PERSONAL, at(22, 18, 0))), exams, UsageFocus.FITNESS, NOW, ZONE, 7,
                List.of(), false, null, NO_SUMMARY, List.of())).reminders();

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.PERSONAL_EVENT);
            assertThat(i.at()).isEqualTo(at(22, 17, 45));
        });
    }

    @Test
    void theChosenDaysBeforeApplyToDeadlines() {
        UUID exam = UUID.randomUUID();
        List<ReminderPlan.Item> items = plan(List.of(),
                List.of(new ReminderPlanner.Deadline(exam, true, "Parcial", at(28, 9, 0))),
                options(null, Set.of(7, 1), null, null, true), List.of(), List.of());

        // El de 7 días (el 21 a las 18:00) aún está a tiempo; el del día antes, el 27.
        assertThat(items).extracting(ReminderPlan.Item::at).containsExactly(at(21, 18, 0), at(27, 18, 0));
    }

    @Test
    void aTaskWithItsOwnDeadlineReminderIsOnlyMentionedThere() {
        UUID deadline = UUID.randomUUID();
        DatedTask t = task("Entregar práctica", DatedTask.Anchor.DEADLINE, deadline, at(24, 23, 0));
        List<ReminderPlan.Item> items = plan(List.of(),
                List.of(new ReminderPlanner.Deadline(deadline, false, "Práctica 2", at(24, 23, 0))), NO_SUMMARY,
                List.of(t), List.of());

        assertThat(items).noneMatch(i -> i.kind() == ReminderKind.CHALLENGE_TASK);
        assertThat(items).filteredOn(i -> i.kind() == ReminderKind.DEADLINE).isNotEmpty()
                .allSatisfy(i -> assertThat(i.tasks()).containsExactly(t.mention()));
    }

    @Test
    void aTaskOnAnEventWithReminderIsMentionedThere() {
        UUID event = UUID.randomUUID();
        DatedTask t = task("Repasar tema 3", DatedTask.Anchor.EVENT, event, at(22, 18, 0));
        List<ReminderPlan.Item> items = plan(List.of(block(event, ActivityType.STUDY, at(22, 18, 0))), List.of(),
                NO_SUMMARY, List.of(t), List.of());

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.STUDY);
            assertThat(i.tasks()).containsExactly(t.mention());
        });
    }

    @Test
    void aTaskWithoutOtherReminderGetsItsOwnTheEveningBefore() {
        UUID day = UUID.randomUUID();
        DatedTask t = task("Pierna", DatedTask.Anchor.ROUTINE_DAY, day, at(23, 0, 0));
        List<ReminderPlan.Item> items = plan(List.of(), List.of(), NO_SUMMARY, List.of(t), List.of());

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.CHALLENGE_TASK);
            assertThat(i.at()).isEqualTo(at(22, 18, 0));
            assertThat(i.count()).isEqualTo(1);
            assertThat(i.targetId()).isEqualTo(CHALLENGE.toString());
            assertThat(i.tasks()).containsExactly(t.mention());
        });
    }

    @Test
    void aMorningTaskGoesInsideTheSummary() {
        UUID day = UUID.randomUUID();
        DatedTask t = task("Pierna", DatedTask.Anchor.ROUTINE_DAY, day, at(23, 0, 0));
        List<ReminderPlan.Item> items = plan(List.of(), List.of(),
                options(null, null, ReminderOptions.TaskTiming.MORNING_OF, null, false), List.of(t), List.of());

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.MORNING_SUMMARY);
            assertThat(i.at()).isEqualTo(at(23, 8, 0));
            assertThat(i.summary().tasks()).isEqualTo(1);
        });
    }

    @Test
    void theSummaryOnlyComesWhenThereIsSomething() {
        assertThat(plan(List.of(), List.of(), ReminderOptions.DEFAULTS, List.of(), List.of())).isEmpty();
    }

    @Test
    void theSummaryCountsWhatComesAfterItAndEachThingOnce() {
        UUID study = UUID.randomUUID();
        UUID deadline = UUID.randomUUID();
        List<ReminderPlanner.Block> blocks = List.of(
                block(UUID.randomUUID(), ActivityType.SPORT, at(22, 7, 0)), // antes del resumen: no cuenta
                block(study, ActivityType.STUDY, at(22, 10, 0)),
                block(UUID.randomUUID(), ActivityType.REVIEW, at(22, 12, 0)),
                block(UUID.randomUUID(), ActivityType.SPORT, at(22, 19, 0)),
                block(UUID.randomUUID(), ActivityType.PERSONAL, at(22, 17, 0)),
                block(UUID.randomUUID(), ActivityType.REST, at(22, 15, 0)));
        // La tarea va con el estudio y la otra con la entrega: no se cuentan otra vez.
        List<DatedTask> tasks = List.of(task("Tema 3", DatedTask.Anchor.EVENT, study, at(22, 10, 0)),
                task("Práctica", DatedTask.Anchor.DEADLINE, deadline, at(22, 23, 0)),
                task("Pierna", DatedTask.Anchor.ROUTINE_DAY, UUID.randomUUID(), at(22, 0, 0)));

        List<ReminderPlan.Item> items = plan(blocks,
                List.of(new ReminderPlanner.Deadline(deadline, false, "Física", at(22, 23, 0))),
                ReminderOptions.DEFAULTS, tasks, List.of());

        assertThat(items).filteredOn(i -> i.kind() == ReminderKind.MORNING_SUMMARY).singleElement()
                .satisfies(i -> {
                    assertThat(i.at()).isEqualTo(at(22, 8, 0));
                    assertThat(i.summary()).isEqualTo(new ReminderPlan.DaySummary(2, 1, 0, 1,
                            List.of(new ReminderPlan.SummaryDeadline("Física", false)), 1, false));
                });
    }

    @Test
    void theSummaryAbsorbsTheCheckInOfThatMorning() {
        UUID study = UUID.randomUUID();
        List<ReminderPlan.Item> checkIns = List.of(
                new ReminderPlan.Item(ReminderKind.CHECK_IN, at(22, 9, 0), "2026-10-22", null, null, null),
                new ReminderPlan.Item(ReminderKind.CHECK_IN, at(23, 9, 0), "2026-10-23", null, null, null));

        List<ReminderPlan.Item> items = plan(List.of(block(study, ActivityType.STUDY, at(22, 18, 0))), List.of(),
                ReminderOptions.DEFAULTS, List.of(), checkIns);

        // El jueves llega un solo aviso por la mañana; el viernes, sin nada planeado, el registro va solo.
        assertThat(items).filteredOn(i -> i.at().isBefore(at(22, 12, 0))).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.MORNING_SUMMARY);
            assertThat(i.summary().checkIn()).isTrue();
        });
        assertThat(items).filteredOn(i -> i.kind() == ReminderKind.CHECK_IN)
                .extracting(ReminderPlan.Item::refId).containsExactly("2026-10-23");
    }

    @Test
    void theSummaryCountsTowardsTheDailyLimit() {
        NotificationPreferences one = new NotificationPreferences(UUID.randomUUID(), USER,
                EnumSet.allOf(NotificationType.class), null, null, 1, NotificationMode.NORMAL, NOW, NOW);
        List<ReminderPlan.Item> items = planner.plan(new ReminderPlanner.Input(0,
                List.of(block(UUID.randomUUID(), ActivityType.STUDY, at(22, 18, 0))), one, UsageFocus.BOTH, NOW,
                ZONE, 7, List.of(), false, null, ReminderOptions.DEFAULTS, List.of())).reminders();

        assertThat(items).extracting(ReminderPlan.Item::kind).containsExactly(ReminderKind.MORNING_SUMMARY);
    }

    @Test
    void defaultsKeepTheFormerBehaviour() {
        ReminderOptions d = ReminderOptions.DEFAULTS;

        assertThat(d.eventLeadMinutes()).isEqualTo(15);
        assertThat(d.deadlineDaysBefore()).containsExactly(3, 1);
        assertThat(d.taskTiming()).isEqualTo(ReminderOptions.TaskTiming.EVENING_BEFORE);
        assertThat(d.morningSummaryAt()).isEqualTo(LocalTime.of(8, 0));
    }

    @Test
    void onlyTheClosedOptionsAreAccepted() {
        assertThatThrownBy(() -> options(10, null, null, null, false))
                .isInstanceOf(ReminderOptionsInvalidException.class);
        assertThatThrownBy(() -> options(null, Set.of(2), null, null, false))
                .isInstanceOf(ReminderOptionsInvalidException.class);
        assertThatThrownBy(() -> options(null, Set.of(), null, null, false))
                .isInstanceOf(ReminderOptionsInvalidException.class);
        java.util.Set<Integer> withNull = new java.util.HashSet<>();
        withNull.add(null);
        assertThatThrownBy(() -> options(null, withNull, null, null, false))
                .isInstanceOf(ReminderOptionsInvalidException.class);
        assertThatThrownBy(() -> options(null, null, null, LocalTime.of(8, 15), false))
                .isInstanceOf(ReminderOptionsInvalidException.class);
        assertThatThrownBy(() -> options(null, null, null, LocalTime.of(13, 0), false))
                .isInstanceOf(ReminderOptionsInvalidException.class);
    }

    @Test
    void aPartialChangeKeepsTheRest() {
        ReminderOptions chosen = options(30, Set.of(7), ReminderOptions.TaskTiming.MORNING_OF, LocalTime.of(7, 30),
                false);

        ReminderOptions changed = chosen.with(ReminderOptions.Change.switches(false, true, true));

        assertThat(changed.streak()).isFalse();
        assertThat(changed.eventLeadMinutes()).isEqualTo(30);
        assertThat(changed.deadlineDaysBefore()).containsExactly(7);
        assertThat(changed.morningSummaryAt()).isEqualTo(LocalTime.of(7, 30));
        ReminderOptions off = chosen.with(new ReminderOptions.Change(null, null, null, null, null, null, null, false));
        assertThat(off.morningSummary()).isFalse();
        // Encender sin hora vuelve a las 8:00.
        assertThat(off.with(new ReminderOptions.Change(null, null, null, null, null, null, null, true))
                .morningSummaryAt()).isEqualTo(LocalTime.of(8, 0));
    }

    @Test
    void aMorningTaskBeforeALateSummaryKeepsItsOwnReminder() {
        UUID event = UUID.randomUUID();
        // Tarea en un evento de las 10:00 que no avisa (clase con los avisos de clase apagados) y resumen a las 12:00.
        DatedTask t = task("Repasar tema 3", DatedTask.Anchor.EVENT, event, at(22, 10, 0));
        List<ReminderPlan.Item> items = plan(List.of(), List.of(),
                options(null, null, ReminderOptions.TaskTiming.MORNING_OF, LocalTime.of(12, 0), false), List.of(t),
                List.of());

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.CHALLENGE_TASK);
            assertThat(i.at()).isEqualTo(at(22, 8, 0));
            assertThat(i.count()).isZero();
        });
    }
}
