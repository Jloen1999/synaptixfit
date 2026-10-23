package com.synaptixfit.domain.model.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.notification.NotificationInvalidQuietHoursException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class NotificationPreferencesTest {

    private static final Instant NOW = Instant.parse("2026-10-15T10:00:00Z");
    private static final LocalTime NOON = LocalTime.NOON;

    private final NotificationPreferences prefs = NotificationPreferences.defaults(UUID.randomUUID(), NOW);

    @Test
    void defaultsDeliverEverythingUpToTen() {
        assertThat(prefs.activeCategories()).containsExactlyInAnyOrder(NotificationType.values());
        assertThat(prefs.dailyLimit()).isEqualTo(10);
        assertThat(prefs.evaluate(NotificationType.SOCIAL, NotificationPriority.INFORMATIVE, NOON, 9))
                .isEqualTo(DeliveryDecision.DELIVER);
        assertThat(prefs.evaluate(NotificationType.SOCIAL, NotificationPriority.INFORMATIVE, NOON, 10))
                .isEqualTo(DeliveryDecision.SUPPRESSED_DAILY_LIMIT);
    }

    @Test
    void quietHoursCrossingMidnight() {
        prefs.update(EnumSet.allOf(NotificationType.class), LocalTime.of(23, 0), LocalTime.of(7, 0), 10,
                NotificationMode.NORMAL, NOW);
        assertThat(prefs.inQuietHours(LocalTime.of(23, 0))).isTrue();
        assertThat(prefs.inQuietHours(LocalTime.of(2, 30))).isTrue();
        assertThat(prefs.inQuietHours(LocalTime.of(7, 0))).isFalse();
        assertThat(prefs.inQuietHours(LocalTime.of(22, 59))).isFalse();
        assertThat(prefs.evaluate(NotificationType.MILESTONE, NotificationPriority.RECOMMENDED,
                LocalTime.of(1, 0), 0)).isEqualTo(DeliveryDecision.SUPPRESSED_QUIET_HOURS);
    }

    @Test
    void quietHoursWithinTheSameDay() {
        prefs.update(Set.of(NotificationType.SOCIAL), LocalTime.of(14, 0), LocalTime.of(16, 0), 10,
                NotificationMode.NORMAL, NOW);
        assertThat(prefs.inQuietHours(LocalTime.of(15, 0))).isTrue();
        assertThat(prefs.inQuietHours(LocalTime.of(16, 0))).isFalse();
        assertThat(prefs.inQuietHours(LocalTime.of(13, 59))).isFalse();
    }

    @Test
    void criticalAlwaysDelivered() {
        prefs.update(Set.of(), LocalTime.of(0, 0), LocalTime.of(23, 59), 0, NotificationMode.REST, NOW);
        assertThat(prefs.evaluate(NotificationType.CONFLICT, NotificationPriority.CRITICAL, NOON, 100))
                .isEqualTo(DeliveryDecision.DELIVER);
    }

    @Test
    void inactiveCategoryAndModesSuppress() {
        prefs.update(Set.of(NotificationType.ACADEMIC, NotificationType.SOCIAL), null, null, 10,
                NotificationMode.EXAMS, NOW);
        assertThat(prefs.evaluate(NotificationType.MILESTONE, NotificationPriority.INFORMATIVE, NOON, 0))
                .isEqualTo(DeliveryDecision.SUPPRESSED_CATEGORY);
        assertThat(prefs.evaluate(NotificationType.SOCIAL, NotificationPriority.INFORMATIVE, NOON, 0))
                .isEqualTo(DeliveryDecision.SUPPRESSED_MODE);
        assertThat(prefs.evaluate(NotificationType.ACADEMIC, NotificationPriority.RECOMMENDED, NOON, 0))
                .isEqualTo(DeliveryDecision.DELIVER);

        prefs.update(Set.of(NotificationType.ACADEMIC), null, null, 10, NotificationMode.REST, NOW);
        assertThat(prefs.evaluate(NotificationType.ACADEMIC, NotificationPriority.RECOMMENDED, NOON, 0))
                .isEqualTo(DeliveryDecision.SUPPRESSED_MODE);
    }

    @Test
    void invalidValuesAreRejected() {
        assertThatThrownBy(() -> prefs.update(Set.of(), LocalTime.of(22, 0), null, 10, NotificationMode.NORMAL, NOW))
                .isInstanceOf(NotificationInvalidQuietHoursException.class);
        assertThatThrownBy(() -> prefs.update(Set.of(), LocalTime.of(22, 0), LocalTime.of(22, 0), 10,
                NotificationMode.NORMAL, NOW)).isInstanceOf(NotificationInvalidQuietHoursException.class);
        assertThatThrownBy(() -> prefs.update(Set.of(), null, null, 51, NotificationMode.NORMAL, NOW))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void afterQuietHoursMovesToTheEndOfTheSilence() {
        prefs.update(EnumSet.allOf(NotificationType.class), LocalTime.of(23, 0), LocalTime.of(7, 0), 10,
                NotificationMode.NORMAL, NOW);
        LocalDateTime evening = LocalDateTime.of(2026, 10, 15, 23, 30);
        LocalDateTime night = LocalDateTime.of(2026, 10, 16, 2, 0);
        LocalDateTime day = LocalDateTime.of(2026, 10, 16, 12, 0);
        assertThat(prefs.afterQuietHours(evening)).isEqualTo(LocalDateTime.of(2026, 10, 16, 7, 0));
        assertThat(prefs.afterQuietHours(night)).isEqualTo(LocalDateTime.of(2026, 10, 16, 7, 0));
        assertThat(prefs.afterQuietHours(day)).isEqualTo(day);
    }

    @Test
    void admitsCombinesCategoryAndMode() {
        prefs.update(Set.of(NotificationType.ACADEMIC, NotificationType.SOCIAL), null, null, 10,
                NotificationMode.EXAMS, NOW);
        assertThat(prefs.admits(NotificationType.ACADEMIC)).isTrue();
        assertThat(prefs.admits(NotificationType.SOCIAL)).isFalse();
        assertThat(prefs.admits(NotificationType.MILESTONE)).isFalse();
    }

    @Test
    void notificationMarkReadIsIdempotent() {
        Notification n = Notification.create(UUID.randomUUID(), "T", null, NotificationPriority.INFORMATIVE,
                NotificationType.SOCIAL, null, null, NOW);
        n.markRead(NOW);
        n.markRead(NOW.plusSeconds(60));
        assertThat(n.read()).isTrue();
        assertThat(n.readAt()).isEqualTo(NOW);
    }
}
