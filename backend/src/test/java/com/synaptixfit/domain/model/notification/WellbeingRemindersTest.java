package com.synaptixfit.domain.model.notification;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.model.user.UsageFocus;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Racha en riesgo, registro diario y clase en 15 minutos, con sus opciones y categorías. */
class WellbeingRemindersTest {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    // Miércoles 4 de noviembre, 08:00 en Madrid.
    private static final Instant NOW = Instant.parse("2026-11-04T07:00:00Z");
    private static final Instant END = NOW.plus(Duration.ofDays(2));
    private final NotificationPreferences prefs = NotificationPreferences.defaults(UUID.randomUUID(), NOW);

    private WellbeingReminders.Input input(ReminderOptions options, int streak, boolean active, boolean checkIn,
                                           List<WellbeingReminders.ClassBlock> classes) {
        return new WellbeingReminders.Input(prefs, UsageFocus.BOTH, options, NOW, ZONE, END, streak, active, checkIn,
                classes);
    }

    @Test
    void rachaEnRiesgoHoyALasOchoSiAunNoHayActividad() {
        List<ReminderPlan.Item> items = WellbeingReminders.plan(input(new ReminderOptions(true, false, false), 5,
                false, false, List.of()));
        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.STREAK_AT_RISK);
            assertThat(i.at()).isEqualTo(Instant.parse("2026-11-04T19:00:00Z"));
            assertThat(i.count()).isEqualTo(5);
        });
        assertThat(WellbeingReminders.plan(input(ReminderOptions.DEFAULTS, 5, true, true, List.of()))
                .stream().map(ReminderPlan.Item::kind)).doesNotContain(ReminderKind.STREAK_AT_RISK);
    }

    @Test
    void registroDiarioCadaMananaYHoySoloSiFalta() {
        ReminderOptions onlyCheckIn = new ReminderOptions(false, true, false);
        List<ReminderPlan.Item> pending = WellbeingReminders.plan(input(onlyCheckIn, 0, false, false, List.of()));
        assertThat(pending).extracting(ReminderPlan.Item::refId)
                .containsExactly("2026-11-04", "2026-11-05");
        List<ReminderPlan.Item> done = WellbeingReminders.plan(input(onlyCheckIn, 0, false, true, List.of()));
        assertThat(done).extracting(ReminderPlan.Item::refId).containsExactly("2026-11-05");
    }

    @Test
    void claseQuinceMinutosAntesConElAulaYNoSiNoFuiste() {
        Instant start = Instant.parse("2026-11-04T09:00:00Z");
        WellbeingReminders.ClassBlock clase = new WellbeingReminders.ClassBlock(UUID.randomUUID(), "Cálculo",
                "Aula 2.03", start, false);
        WellbeingReminders.ClassBlock skipped = new WellbeingReminders.ClassBlock(UUID.randomUUID(), "Física",
                null, start.plus(Duration.ofHours(2)), true);
        List<ReminderPlan.Item> items = WellbeingReminders.plan(input(new ReminderOptions(false, false, true), 0,
                false, true, List.of(clase, skipped)));
        assertThat(items).singleElement().satisfies(i -> {
            assertThat(i.kind()).isEqualTo(ReminderKind.CLASS_SOON);
            assertThat(i.at()).isEqualTo(start.minus(Duration.ofMinutes(15)));
            assertThat(i.place()).isEqualTo("Aula 2.03");
            assertThat(i.title()).isEqualTo("Cálculo");
        });
    }

    @Test
    void conTodoApagadoNoHayAvisos() {
        assertThat(WellbeingReminders.plan(input(new ReminderOptions(false, false, false), 9, false, false,
                List.of()))).isEmpty();
    }
}
