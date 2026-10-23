package com.synaptixfit.application.service.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.event.gamification.LevelUp;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Experiencia: solo la subida de nivel se anuncia (Notificaciones la celebra). */
class ExperienceServiceTest {

    private final UUID userId = UUID.randomUUID();
    private User user = User.builder().id(userId).email("ana@example.com").fullName("Ana").passwordHash("h").build();
    private final List<DomainEvent> events = new ArrayList<>();
    private final ExperienceService service = new ExperienceService(new UserRepositoryPort() {
        public Optional<User> findById(UUID id) { return Optional.of(user); }
        public Optional<User> findByEmail(String e) { return Optional.empty(); }
        public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
        public boolean existsByEmail(String e) { return false; }
        public User save(User u) { user = u; return u; }
    }, events::add, Clock.fixed(Instant.parse("2026-10-18T10:00:00Z"), ZoneOffset.UTC));

    @Test
    void levelUpIsPublishedOnlyWhenTheLevelIncreases() {
        service.award(userId, 10);
        assertThat(events).isEmpty();

        var change = service.award(userId, 10_000);
        assertThat(change.leveledUp()).isTrue();
        assertThat(events).singleElement().isInstanceOfSatisfying(LevelUp.class,
                e -> assertThat(e.level()).isEqualTo(change.level()));

        service.revoke(userId, 10_000);
        assertThat(events).hasSize(1);
    }
}
