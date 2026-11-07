package com.synaptixfit.domain.model.notification;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.user.BirthDate;
import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * Felicitación de cumpleaños del plan de avisos (ADR 0036): por la mañana, después del silencio, dentro del resumen de
 * la mañana si lo hay y el 28 de febrero para quien nació un 29 en los años no bisiestos.
 */
class ReminderBirthdayTest {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    private static final UUID USER = UUID.randomUUID();

    private final ReminderPlanner planner = new ReminderPlanner();

    private static Instant at(int year, int month, int day, int h, int min) {
        return LocalDateTime.of(year, month, day, h, min).atZone(ZONE).toInstant();
    }

    private static NotificationPreferences prefs(Set<NotificationType> categories, LocalTime quietStart,
                                                 LocalTime quietEnd) {
        Instant now = at(2026, 10, 1, 0, 0);
        return new NotificationPreferences(UUID.randomUUID(), USER, categories, quietStart, quietEnd, 20,
                NotificationMode.NORMAL, now, now);
    }

    private static NotificationPreferences allOn() {
        return prefs(EnumSet.allOf(NotificationType.class), null, null);
    }

    private static final ReminderOptions NO_SUMMARY = ReminderOptions.DEFAULTS.with(new ReminderOptions.Change(null,
            null, null, null, null, null, null, Boolean.FALSE));

    private static ReminderPlanner.Birthday birthday(int year, int month, int day) {
        return new ReminderPlanner.Birthday(new BirthDate(LocalDate.of(year, month, day)), "Ana");
    }

    private List<ReminderPlan.Item> plan(Instant now, NotificationPreferences prefs, ReminderOptions options,
                                         List<ReminderPlanner.Block> blocks, ReminderPlanner.Birthday birthday) {
        return planner.plan(new ReminderPlanner.Input(0, blocks, prefs, UsageFocus.BOTH, now, ZONE, 7, List.of(),
                false, null, options, List.of(), birthday)).reminders();
    }

    @Test
    void withoutMorningSummaryTheGreetingArrivesAloneAtNine() {
        List<ReminderPlan.Item> items = plan(at(2026, 11, 7, 20, 0), allOn(), NO_SUMMARY, List.of(),
                birthday(2004, 11, 9));

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.BIRTHDAY);
            assertThat(i.at()).isEqualTo(at(2026, 11, 9, 9, 0));
            assertThat(i.title()).isEqualTo("Ana");
        });
    }

    @Test
    void onADayWithMorningSummaryTheGreetingGoesInsideIt() {
        UUID study = UUID.randomUUID();
        List<ReminderPlan.Item> items = plan(at(2026, 11, 7, 20, 0), allOn(), ReminderOptions.DEFAULTS,
                List.of(new ReminderPlanner.Block(study, ActivityType.STUDY, at(2026, 11, 9, 17, 0), "Física",
                        false)),
                birthday(2004, 11, 9));

        assertThat(items).noneMatch(i -> i.kind() == ReminderKind.BIRTHDAY);
        assertThat(items).filteredOn(i -> i.kind() == ReminderKind.MORNING_SUMMARY).singleElement()
                .satisfies(i -> {
                    assertThat(i.summary().birthday()).isTrue();
                    assertThat(i.title()).isEqualTo("Ana");
                    assertThat(i.at()).isEqualTo(at(2026, 11, 9, 8, 0));
                });
    }

    @Test
    void withMorningSummaryButNothingPlannedTheGreetingTakesTheSummaryTime() {
        List<ReminderPlan.Item> items = plan(at(2026, 11, 7, 20, 0), allOn(), ReminderOptions.DEFAULTS, List.of(),
                birthday(2004, 11, 9));

        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.BIRTHDAY);
            assertThat(i.at()).isEqualTo(at(2026, 11, 9, 8, 0));
        });
    }

    @Test
    void quietHoursDelayTheGreeting() {
        NotificationPreferences quiet = prefs(EnumSet.allOf(NotificationType.class), LocalTime.of(23, 0),
                LocalTime.of(10, 30));
        List<ReminderPlan.Item> items = plan(at(2026, 11, 7, 20, 0), quiet, NO_SUMMARY, List.of(),
                birthday(2004, 11, 9));

        assertThat(items).singleElement().satisfies(i -> assertThat(i.at()).isEqualTo(at(2026, 11, 9, 10, 30)));
    }

    @Test
    void leapDayBirthdaysAreGreetedOnThe28thInCommonYears() {
        List<ReminderPlan.Item> items = plan(at(2027, 2, 26, 12, 0), allOn(), NO_SUMMARY, List.of(),
                birthday(2004, 2, 29));

        assertThat(items).singleElement().satisfies(i -> assertThat(i.at()).isEqualTo(at(2027, 2, 28, 9, 0)));
    }

    @Test
    void noGreetingWithoutBirthDateOrWithEverythingMuted() {
        assertThat(plan(at(2026, 11, 7, 20, 0), allOn(), NO_SUMMARY, List.of(), null)).isEmpty();
        assertThat(plan(at(2026, 11, 7, 20, 0), prefs(EnumSet.noneOf(NotificationType.class), null, null),
                NO_SUMMARY, List.of(), birthday(2004, 11, 9))).isEmpty();
    }

    @Test
    void aBirthdayOutsideTheWindowOrAlreadyPastIsNotPlanned() {
        assertThat(plan(at(2026, 11, 9, 12, 0), allOn(), NO_SUMMARY, List.of(), birthday(2004, 11, 9))).isEmpty();
        assertThat(plan(at(2026, 11, 7, 20, 0), allOn(), NO_SUMMARY, List.of(), birthday(2004, 12, 1))).isEmpty();
    }
}
