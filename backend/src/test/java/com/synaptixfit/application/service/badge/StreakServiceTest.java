package com.synaptixfit.application.service.badge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.synaptixfit.domain.exception.badge.StreakPauseLimitReachedException;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.badge.StreakPause;
import com.synaptixfit.domain.model.badge.StreakStatus;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** «Pausar racha» y «Reanudar» (ADR 0042) sobre {@link StreakService}, con dobles en memoria. */
class StreakServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-15T10:00:00Z");
    private static final LocalDate TODAY = LocalDate.of(2026, 11, 15);
    private static final UUID USER = UUID.randomUUID();

    private final Map<UUID, StreakPause> stored = new LinkedHashMap<>();
    private final Set<LocalDate> activeDays = new HashSet<>();
    private StreakService service;

    @BeforeEach
    void setUp() {
        for (int i = 1; i <= 5; i++) {
            activeDays.add(TODAY.minusDays(i));
        }
        UserActivityPort activity = new UserActivityPort() {
            public Set<LocalDate> activeDays(UUID u, ZoneId z) { return activeDays; }
            public BadgeActivitySnapshot snapshot(UUID u, ZoneId z) { return null; }
        };
        StreakPauseRepositoryPort pauses = new StreakPauseRepositoryPort() {
            public List<StreakPause> findByUser(UUID u) { return new ArrayList<>(stored.values()); }
            public StreakPause save(StreakPause p) { stored.put(p.id(), p); return p; }
            public void delete(UUID id) { stored.remove(id); }
        };
        UserRepositoryPort users = mock(UserRepositoryPort.class);
        when(users.findById(USER)).thenReturn(Optional.empty());
        service = new StreakService(activity, users, pauses, Clock.fixed(NOW, ZoneOffset.UTC), ZoneOffset.UTC);
    }

    @Test
    void pausingStartsTodayAndIsIdempotent() {
        StreakStatus status = service.pause(USER, null);
        service.pause(USER, null);

        assertThat(stored).hasSize(1);
        assertThat(status.pause().from()).isEqualTo(TODAY);
        assertThat(status.canPause()).isFalse();
        assertThat(status.currentDays()).isEqualTo(5);
    }

    @Test
    void resumingTheSameDayRemovesThePause() {
        service.pause(USER, null);

        StreakStatus status = service.resume(USER, null);

        assertThat(stored).isEmpty();
        assertThat(status.pause()).isNull();
        assertThat(status.canPause()).isTrue();
    }

    @Test
    void resumingLaterKeepsThePastPausedDays() {
        StreakPause running = new StreakPause(UUID.randomUUID(), USER, TODAY.minusDays(2),
                TODAY.plusDays(4), NOW);
        stored.put(running.id(), running);
        activeDays.remove(TODAY.minusDays(1));
        activeDays.remove(TODAY.minusDays(2));

        StreakStatus status = service.resume(USER, null);

        assertThat(stored.get(running.id()).to()).isEqualTo(TODAY.minusDays(1));
        // Los dos días en pausa sin actividad no cortaron la racha.
        assertThat(status.currentDays()).isEqualTo(3);
    }

    @Test
    void withoutAStreakPausingDoesNothing() {
        activeDays.clear();

        StreakStatus status = service.pause(USER, null);

        assertThat(stored).isEmpty();
        assertThat(status.pause()).isNull();
    }

    @Test
    void withoutDaysLeftPausingIsRejected() {
        StreakPause a = new StreakPause(UUID.randomUUID(), USER, TODAY.minusDays(30),
                TODAY.minusDays(24), NOW);
        StreakPause b = new StreakPause(UUID.randomUUID(), USER, TODAY.minusDays(12),
                TODAY.minusDays(6), NOW);
        stored.put(a.id(), a);
        stored.put(b.id(), b);

        assertThatThrownBy(() -> service.pause(USER, null))
                .isInstanceOf(StreakPauseLimitReachedException.class);
    }
}
