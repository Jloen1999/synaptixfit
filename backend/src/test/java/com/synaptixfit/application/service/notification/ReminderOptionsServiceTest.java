package com.synaptixfit.application.service.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.notification.ReminderOptionsInvalidException;
import com.synaptixfit.domain.model.notification.ReminderOptions;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Opciones de avisos: el cambio parcial se aplica sobre lo guardado y solo se guarda si es válido (ADR 0035). */
class ReminderOptionsServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-07T10:00:00Z");
    private static final UUID USER = UUID.randomUUID();

    /** Doble en memoria que recuerda cuándo se guardó. */
    private static final class InMemoryOptions implements ReminderOptionsRepositoryPort {
        final Map<UUID, ReminderOptions> stored = new HashMap<>();
        Instant savedAt;

        @Override
        public Optional<ReminderOptions> find(UUID userId) {
            return Optional.ofNullable(stored.get(userId));
        }

        @Override
        public void save(UUID userId, ReminderOptions options, Instant now) {
            stored.put(userId, options);
            savedAt = now;
        }
    }

    private final InMemoryOptions repository = new InMemoryOptions();
    private final ReminderOptionsService service = new ReminderOptionsService(repository,
            Clock.fixed(NOW, ZoneOffset.UTC));

    @Test
    void withoutAnythingSavedTheChangeAppliesToTheDefaults() {
        ReminderOptions changed = service.change(USER, new ReminderOptions.Change(null, false, null, 30, null, null,
                null, null));

        assertThat(changed.checkIn()).isFalse();
        assertThat(changed.eventLeadMinutes()).isEqualTo(30);
        assertThat(changed.deadlineDaysBefore()).containsExactly(3, 1);
        assertThat(changed.morningSummaryAt()).isEqualTo(LocalTime.of(8, 0));
        assertThat(repository.stored.get(USER)).isEqualTo(changed);
        assertThat(repository.savedAt).isEqualTo(NOW);
        assertThat(service.get(USER)).isEqualTo(changed);
    }

    @Test
    void anInvalidChangeIsNotSaved() {
        service.change(USER, ReminderOptions.Change.switches(true, true, false));

        assertThatThrownBy(() -> service.change(USER, new ReminderOptions.Change(null, null, null, null, Set.of(2),
                null, null, null))).isInstanceOf(ReminderOptionsInvalidException.class);
        assertThat(service.get(USER).classes()).isFalse();
        assertThat(service.get(USER).deadlineDaysBefore()).containsExactly(3, 1);
    }
}
