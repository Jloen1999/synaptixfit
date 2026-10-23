package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.NotifyFatigueAlertUseCase;
import com.synaptixfit.application.port.input.notification.NotifyAchievementUseCase;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.notification.UpdateNotificationPreferencesUseCase;
import com.synaptixfit.domain.exception.notification.NotificationNotFoundException;
import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationMode;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.model.notification.UnreadCounts;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class NotificationServicesTest {

    // 01:30 en Madrid (23:30 UTC del día anterior).
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-10-14T23:30:00Z"), ZoneOffset.UTC);

    private final Map<UUID, Notification> store = new HashMap<>();
    private final Map<UUID, NotificationPreferences> prefsStore = new HashMap<>();
    private NotificationRepositoryPort repo;
    private NotificationService notifications;
    private NotificationPreferencesService preferences;
    private final UUID user = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        repo = new NotificationRepositoryPort() {
            public Notification save(Notification n) { store.put(n.id(), n); return n; }
            public Optional<Notification> findById(UUID id) { return Optional.ofNullable(store.get(id)); }
            public PageResult<Notification> findByUser(UUID u, boolean unreadOnly, NotificationPriority p,
                                                       PageRequest page) {
                var items = store.values().stream().filter(n -> n.userId().equals(u))
                        .filter(n -> !unreadOnly || !n.read()).toList();
                return new PageResult<>(items, page.page(), page.size(), items.size());
            }
            public UnreadCounts countUnread(UUID u) {
                return new UnreadCounts(0, 0, store.values().stream().filter(n -> !n.read()).count());
            }
            public int markAllRead(UUID u, Instant at) {
                int count = 0;
                for (Notification n : store.values()) {
                    if (n.userId().equals(u) && !n.read()) {
                        n.markRead(at);
                        count++;
                    }
                }
                return count;
            }
            public void delete(UUID id) { store.remove(id); }
            public long countCreatedSince(UUID u, Instant since) {
                return store.values().stream()
                        .filter(n -> n.userId().equals(u) && !n.createdAt().isBefore(since)).count();
            }
            public boolean existsByReferenceKey(UUID u, String referenceKey) {
                return store.values().stream().anyMatch(n -> n.userId().equals(u)
                        && referenceKey.equals(n.referenceKey()));
            }
        };
        NotificationPreferencesRepositoryPort prefsRepo = new NotificationPreferencesRepositoryPort() {
            public Optional<NotificationPreferences> findByUserId(UUID u) {
                return Optional.ofNullable(prefsStore.get(u));
            }
            public NotificationPreferences save(NotificationPreferences p) { prefsStore.put(p.userId(), p); return p; }
        };
        notifications = new NotificationService(repo, prefsRepo, CLOCK, ZoneId.of("Europe/Madrid"));
        preferences = new NotificationPreferencesService(prefsRepo, CLOCK);
    }

    private CreateNotificationUseCase.Command social() {
        return new CreateNotificationUseCase.Command(user, "Nuevo me gusta", "Ana ha dado me gusta",
                NotificationPriority.INFORMATIVE, NotificationType.SOCIAL, "/social/posts/1", "Ver");
    }

    @Test
    void createsWithDefaultPreferencesWhenNoneStored() {
        assertThat(notifications.create(social())).isPresent();
        assertThat(store).hasSize(1);
    }

    @Test
    void respectsQuietHoursInConfiguredZone() {
        preferences.updatePreferences(new UpdateNotificationPreferencesUseCase.Command(user,
                EnumSet.allOf(NotificationType.class), LocalTime.of(23, 0), LocalTime.of(7, 0), 10,
                NotificationMode.NORMAL));
        assertThat(notifications.create(social())).isEmpty();
        assertThat(store).isEmpty();
    }

    @Test
    void respectsDailyLimitAndDisabledCategory() {
        preferences.updatePreferences(new UpdateNotificationPreferencesUseCase.Command(user,
                Set.of(NotificationType.SOCIAL), null, null, 1, NotificationMode.NORMAL));
        assertThat(notifications.create(social())).isPresent();
        assertThat(notifications.create(social())).isEmpty();

        var milestone = new CreateNotificationUseCase.Command(user, "Hito", null, NotificationPriority.CRITICAL,
                NotificationType.MILESTONE, null, null);
        assertThat(notifications.create(milestone)).isPresent();
    }

    @Test
    void markReadDeleteAndOwnership() {
        Notification n = notifications.create(social()).orElseThrow();
        UUID stranger = UUID.randomUUID();
        assertThatThrownBy(() -> notifications.markRead(stranger, n.id()))
                .isInstanceOf(NotificationNotFoundException.class);
        assertThatThrownBy(() -> notifications.delete(stranger, n.id()))
                .isInstanceOf(NotificationNotFoundException.class);

        assertThat(notifications.markRead(user, n.id()).read()).isTrue();
        notifications.create(social());
        assertThat(notifications.markAllRead(user)).isEqualTo(1);
        notifications.delete(user, n.id());
        assertThat(store).hasSize(1);
    }

    @Test
    void initializeIsIdempotent() {
        preferences.initialize(user);
        NotificationPreferences first = prefsStore.get(user);
        preferences.initialize(user);
        assertThat(prefsStore.get(user)).isSameAs(first);
        assertThat(preferences.getPreferences(user).mode()).isEqualTo(NotificationMode.NORMAL);
    }

    @Test
    void getPreferencesReturnsDefaultsWithoutSaving() {
        assertThat(preferences.getPreferences(user).dailyLimit()).isEqualTo(10);
        assertThat(prefsStore).isEmpty();
    }

    @Test
    void achievementsAreNotifiedOnceAndFatigueOncePerDay() {
        AutomaticNotificationService automatic = new AutomaticNotificationService(notifications, repo, CLOCK,
                ZoneId.of("Europe/Madrid"));
        UUID challenge = UUID.randomUUID();
        var completed = new NotifyAchievementUseCase.Command(user, NotifyAchievementUseCase.Kind.CHALLENGE_COMPLETED,
                "Correr 5 km", challenge);
        automatic.notifyAchievement(completed);
        automatic.notifyAchievement(completed);
        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user, NotifyAchievementUseCase.Kind.LEVEL_UP,
                "3", null));
        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user, NotifyAchievementUseCase.Kind.LEVEL_UP,
                "4", null));
        var fatigue = new NotifyFatigueAlertUseCase.Command(user, NotifyFatigueAlertUseCase.Reason.OVERTRAINING, 1.7);
        automatic.notifyFatigue(fatigue);
        automatic.notifyFatigue(new NotifyFatigueAlertUseCase.Command(user,
                NotifyFatigueAlertUseCase.Reason.OVERTRAINING, 1.9));

        assertThat(store.values()).extracting(Notification::type).containsExactlyInAnyOrder(NotificationType.MILESTONE,
                NotificationType.MILESTONE, NotificationType.MILESTONE, NotificationType.FATIGUE_ALERT);
        assertThat(store.values()).filteredOn(n -> n.type() == NotificationType.MILESTONE)
                .extracting(Notification::actionUrl).contains("/challenges/" + challenge);
    }

    @Test
    void twoChallengesWithTheSameTitleAreBothNotifiedButNeverTwice() {
        AutomaticNotificationService automatic = new AutomaticNotificationService(notifications, repo, CLOCK,
                ZoneId.of("Europe/Madrid"));
        UUID first = UUID.randomUUID();
        UUID second = UUID.randomUUID();

        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user,
                NotifyAchievementUseCase.Kind.CHALLENGE_COMPLETED, "Leer 10 páginas", first));
        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user,
                NotifyAchievementUseCase.Kind.CHALLENGE_COMPLETED, "Leer 10 páginas", second));
        // Recompletar el primero (descompletar y volver a completar) no repite el aviso.
        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user,
                NotifyAchievementUseCase.Kind.CHALLENGE_COMPLETED, "Leer 10 páginas", first));

        assertThat(store.values()).extracting(Notification::actionUrl)
                .containsExactlyInAnyOrder("/challenges/" + first, "/challenges/" + second);
        assertThat(store.values()).extracting(Notification::referenceKey)
                .containsExactlyInAnyOrder("challenge:" + first, "challenge:" + second);
    }

    @Test
    void badgesWithTheSameNameAreDistinguishedByIdAndFatigueByDay() {
        AutomaticNotificationService automatic = new AutomaticNotificationService(notifications, repo, CLOCK,
                ZoneId.of("Europe/Madrid"));
        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user,
                NotifyAchievementUseCase.Kind.BADGE_EARNED, "Constancia", UUID.randomUUID()));
        automatic.notifyAchievement(new NotifyAchievementUseCase.Command(user,
                NotifyAchievementUseCase.Kind.BADGE_EARNED, "Constancia", UUID.randomUUID()));
        automatic.notifyFatigue(new NotifyFatigueAlertUseCase.Command(user,
                NotifyFatigueAlertUseCase.Reason.CHECK_IN_ADAPTATION, null));

        AutomaticNotificationService tomorrow = new AutomaticNotificationService(notifications, repo,
                Clock.offset(CLOCK, java.time.Duration.ofDays(1)), ZoneId.of("Europe/Madrid"));
        tomorrow.notifyFatigue(new NotifyFatigueAlertUseCase.Command(user,
                NotifyFatigueAlertUseCase.Reason.CHECK_IN_ADAPTATION, null));

        assertThat(store.values()).filteredOn(n -> n.type() == NotificationType.MILESTONE).hasSize(2);
        // 23:30 UTC del 14 es ya el 15 en Madrid: el día de la clave es el del usuario.
        assertThat(store.values()).filteredOn(n -> n.type() == NotificationType.FATIGUE_ALERT)
                .extracting(Notification::referenceKey)
                .containsExactlyInAnyOrder("fatigue:check_in_adaptation:2026-10-15",
                        "fatigue:check_in_adaptation:2026-10-16");
    }

    @Test
    void automaticNotificationsRespectDisabledCategories() {
        preferences.updatePreferences(new UpdateNotificationPreferencesUseCase.Command(user,
                Set.of(NotificationType.SOCIAL), null, null, 10, NotificationMode.NORMAL));
        AutomaticNotificationService automatic = new AutomaticNotificationService(notifications, repo, CLOCK,
                ZoneId.of("Europe/Madrid"));

        automatic.notifyFatigue(new NotifyFatigueAlertUseCase.Command(user,
                NotifyFatigueAlertUseCase.Reason.CHECK_IN_ADAPTATION, null));

        assertThat(store).isEmpty();
    }
}
