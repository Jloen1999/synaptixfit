package com.synaptixfit.application.service.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.CreateCalendarFeedUseCase;
import com.synaptixfit.domain.exception.planner.CalendarFeedNotFoundException;
import com.synaptixfit.domain.model.planner.CalendarFeed;
import com.synaptixfit.domain.port.output.planner.CalendarFeedRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** El enlace privado sirve el calendario de su dueño, se sustituye al crear otro y deja de valer al revocarlo. */
class CalendarFeedServiceTest {

    private static final Instant NOW = Instant.parse("2026-10-30T10:00:00Z");
    private final UUID user = UUID.randomUUID();
    private final Map<UUID, CalendarFeed> store = new HashMap<>();
    private final CalendarFeedRepositoryPort port = new CalendarFeedRepositoryPort() {
        public CalendarFeed save(CalendarFeed feed) {
            store.put(feed.userId(), feed);
            return feed;
        }

        public Optional<CalendarFeed> findByUser(UUID userId) {
            return Optional.ofNullable(store.get(userId));
        }

        public Optional<CalendarFeed> findByTokenHash(String hash) {
            return store.values().stream().filter(f -> f.tokenHash().equals(hash)).findFirst();
        }

        public void deleteByUser(UUID userId) {
            store.remove(userId);
        }
    };
    private final CalendarFeedService service = new CalendarFeedService(port,
            (userId, from, to) -> "BEGIN:VCALENDAR " + userId + " " + from + " " + to,
            Clock.fixed(NOW, ZoneOffset.UTC));

    @Test
    void theLinkServesItsOwnersCalendarAndOnlyItsHashIsStored() {
        CreateCalendarFeedUseCase.Result created = service.createFeed(user);

        assertThat(created.token()).hasSizeGreaterThanOrEqualTo(43); // 256 bits en base64url
        assertThat(store.get(user).tokenHash()).isNotEqualTo(created.token()).hasSize(64);
        assertThat(service.activeSince(user)).contains(NOW);
        assertThat(service.readFeed(created.token())).contains(user.toString())
                .contains(NOW.minus(CalendarFeedService.PAST).toString())
                .contains(NOW.plus(CalendarFeedService.AHEAD).toString());
    }

    @Test
    void creatingAnotherLinkOrRevokingInvalidatesThePreviousOne() {
        String first = service.createFeed(user).token();
        String second = service.createFeed(user).token();

        assertThatThrownBy(() -> service.readFeed(first)).isInstanceOf(CalendarFeedNotFoundException.class);
        assertThat(service.readFeed(second)).contains(user.toString());

        service.revokeFeed(user);
        assertThatThrownBy(() -> service.readFeed(second)).isInstanceOf(CalendarFeedNotFoundException.class);
        assertThat(service.activeSince(user)).isEmpty();
        assertThatThrownBy(() -> service.readFeed(" ")).isInstanceOf(CalendarFeedNotFoundException.class);
    }
}
