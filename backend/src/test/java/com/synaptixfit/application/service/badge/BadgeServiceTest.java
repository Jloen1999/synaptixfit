package com.synaptixfit.application.service.badge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.badge.BadgeEvaluation;
import com.synaptixfit.domain.event.DomainEvent;
import com.synaptixfit.domain.event.badge.BadgeEarned;
import com.synaptixfit.domain.exception.badge.BadgeNotFoundException;
import com.synaptixfit.domain.exception.badge.InvalidTimeZoneException;
import com.synaptixfit.domain.model.badge.Badge;
import com.synaptixfit.domain.model.badge.BadgeActivitySnapshot;
import com.synaptixfit.domain.model.badge.BadgeCategory;
import com.synaptixfit.domain.model.badge.BadgeCriterion;
import com.synaptixfit.domain.model.badge.BadgeRarity;
import com.synaptixfit.domain.model.badge.BadgeView;
import com.synaptixfit.domain.model.badge.StreakStatus;
import com.synaptixfit.domain.model.badge.UserBadge;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.badge.BadgeCatalogPort;
import com.synaptixfit.domain.port.output.badge.UserActivityPort;
import com.synaptixfit.domain.port.output.badge.UserBadgeRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** Motor de insignias (otorgado idempotente, punto fijo, eventos) y racha diaria. */
class BadgeServiceTest {

    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-14T21:00:00Z"), ZoneOffset.UTC);
    private static final LocalDate TODAY = LocalDate.parse("2026-10-14");

    private final UUID userId = UUID.randomUUID();
    private final Badge firstSession = badge("Primeros pasos", BadgeCriterion.SESSIONS_COMPLETED, 1, 1);
    private final Badge streak7 = badge("Racha de fuego", BadgeCriterion.STREAK_DAYS, 7, 2);
    private final Badge firstChallenge = badge("Primer reto", BadgeCriterion.CHALLENGES_COMPLETED, 1, 3);
    private final Badge collector = badge("Coleccionista", BadgeCriterion.BADGES_EARNED, 2, 4);

    private final Map<UUID, UserBadge> earned = new HashMap<>();
    private final List<DomainEvent> events = new ArrayList<>();
    private Set<LocalDate> activeDays = new HashSet<>();
    private BadgeActivitySnapshot snapshot;
    private User user;
    private BadgeService service;
    private StreakService streaks;

    private static Badge badge(String name, BadgeCriterion criterion, int value, int order) {
        return new Badge(UUID.randomUUID(), name, name, "🏅", BadgeCategory.SPECIAL, criterion, value,
                BadgeRarity.COMMON, order);
    }

    @BeforeEach
    void setUp() {
        user = User.builder().id(userId).email("u@example.com").fullName("Usuario").passwordHash("h").build();
        snapshot = snapshot(0, 0);
        List<Badge> all = List.of(firstSession, streak7, firstChallenge, collector);
        BadgeCatalogPort catalog = new BadgeCatalogPort() {
            public List<Badge> findAll() { return all; }
            public Optional<Badge> findById(UUID id) { return all.stream().filter(b -> b.id().equals(id)).findFirst(); }
        };
        UserBadgeRepositoryPort userBadges = new UserBadgeRepositoryPort() {
            public List<UserBadge> findByUser(UUID u) { return new ArrayList<>(earned.values()); }
            public Optional<UserBadge> find(UUID u, UUID b) { return Optional.ofNullable(earned.get(b)); }
            public boolean awardIfAbsent(UserBadge b) { return earned.putIfAbsent(b.badgeId(), b) == null; }
            public UserBadge save(UserBadge b) { earned.put(b.badgeId(), b); return b; }
        };
        UserActivityPort activity = new UserActivityPort() {
            public Set<LocalDate> activeDays(UUID u, ZoneId z) { return activeDays; }
            public BadgeActivitySnapshot snapshot(UUID u, ZoneId z) { return snapshot; }
        };
        UserRepositoryPort users = new UserRepositoryPort() {
            public Optional<User> findById(UUID id) { return Optional.of(user); }
            public Optional<User> findByEmail(String e) { return Optional.empty(); }
            public Optional<User> findByGoogleSubject(String s) { return Optional.empty(); }
            public boolean existsByEmail(String e) { return false; }
            public User save(User u) { user = u; return u; }
        };
        streaks = new StreakService(activity, users, CLOCK, ZoneOffset.UTC);
        service = new BadgeService(catalog, userBadges, activity, streaks, events::add, CLOCK, ZoneOffset.UTC);
    }

    private static BadgeActivitySnapshot snapshot(int sessions, int challenges) {
        return new BadgeActivitySnapshot(sessions, 0, Set.of(), Set.of(), 0, 0, 0, 0, 0, challenges, List.of());
    }

    @Test
    void evaluationAwardsMetBadgesOnceAndReachesFixedPoint() {
        snapshot = snapshot(1, 1);

        BadgeEvaluation first = service.evaluateBadges(userId, null);

        // Primeros pasos + Primer reto → 2 insignias → cumple «Coleccionista» en la misma evaluación.
        assertThat(first.newlyEarned()).extracting(v -> v.badge().name())
                .containsExactlyInAnyOrder("Primeros pasos", "Primer reto", "Coleccionista");
        assertThat(events).hasSize(3).allMatch(e -> e instanceof BadgeEarned);

        BadgeEvaluation second = service.evaluateBadges(userId, null);
        assertThat(second.newlyEarned()).isEmpty();
        assertThat(earned).hasSize(3);
    }

    @Test
    void streakCriterionUsesDailyStreakAndUpdatesAccount() {
        for (int i = 0; i < 7; i++) {
            activeDays.add(TODAY.minusDays(i));
        }
        BadgeEvaluation result = service.evaluateBadges(userId, null);
        assertThat(result.streak().currentDays()).isEqualTo(7);
        assertThat(result.newlyEarned()).extracting(v -> v.badge().name()).contains("Racha de fuego");
        assertThat(user.streak()).isEqualTo(7);
    }

    @Test
    void streakEndpointReportsRiskLateInTheUserDay() {
        activeDays.add(TODAY.minusDays(1));
        StreakStatus utc = streaks.getStreak(userId, "UTC");
        assertThat(utc.atRisk()).isTrue();
        // En Tokio ya es el día siguiente (06:00): la racha de ayer (13/10) se ha perdido.
        StreakStatus tokyo = streaks.getStreak(userId, "Asia/Tokyo");
        assertThat(tokyo.currentDays()).isZero();
        assertThatThrownBy(() -> streaks.getStreak(userId, "Mars/Base"))
                .isInstanceOf(InvalidTimeZoneException.class);
    }

    @Test
    void catalogShowsProgressAndEarnedState() {
        snapshot = snapshot(1, 0);
        service.evaluateBadges(userId, null);

        List<BadgeView> catalog = service.getBadgeCatalog(userId, null, null);
        assertThat(catalog).hasSize(4);
        BadgeView session = catalog.stream().filter(v -> v.badge().equals(firstSession)).findFirst().orElseThrow();
        assertThat(session.earned()).isNotNull();
        BadgeView challenge = catalog.stream().filter(v -> v.badge().equals(firstChallenge)).findFirst().orElseThrow();
        assertThat(challenge.earned()).isNull();
        assertThat(challenge.currentValue()).isZero();
    }

    @Test
    void notificationsAndVisibility() {
        snapshot = snapshot(1, 0);
        service.evaluateBadges(userId, null);
        assertThat(service.listUnnotifiedBadges(userId)).hasSize(1);

        service.markBadgesNotified(userId, List.of(firstSession.id()));
        assertThat(service.listUnnotifiedBadges(userId)).isEmpty();

        service.changeBadgeVisibility(userId, firstSession.id(), false);
        assertThat(service.listMyBadges(userId, false)).isEmpty();
        assertThat(service.listMyBadges(userId, true)).hasSize(1);

        assertThatThrownBy(() -> service.markBadgesNotified(userId, List.of(streak7.id())))
                .isInstanceOf(BadgeNotFoundException.class);
    }
}
