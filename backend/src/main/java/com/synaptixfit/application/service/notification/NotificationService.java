package com.synaptixfit.application.service.notification;

import com.synaptixfit.application.port.input.notification.CountUnreadNotificationsUseCase;
import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.notification.DeleteNotificationUseCase;
import com.synaptixfit.application.port.input.notification.ListNotificationsUseCase;
import com.synaptixfit.application.port.input.notification.MarkAllNotificationsReadUseCase;
import com.synaptixfit.application.port.input.notification.MarkNotificationReadUseCase;
import com.synaptixfit.domain.exception.notification.NotificationNotFoundException;
import com.synaptixfit.domain.model.notification.DeliveryDecision;
import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.UnreadCounts;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Centro de notificaciones. La creación aplica las preferencias del receptor; las horas de
 * silencio y el «día» del límite diario se evalúan en la zona horaria configurada.
 */
public class NotificationService implements CreateNotificationUseCase, ListNotificationsUseCase,
        CountUnreadNotificationsUseCase, MarkNotificationReadUseCase, MarkAllNotificationsReadUseCase,
        DeleteNotificationUseCase {

    private final NotificationRepositoryPort notifications;
    private final NotificationPreferencesRepositoryPort preferences;
    private final Clock clock;
    private final ZoneId zone;

    public NotificationService(NotificationRepositoryPort notifications,
                               NotificationPreferencesRepositoryPort preferences, Clock clock, ZoneId zone) {
        this.notifications = notifications;
        this.preferences = preferences;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public Optional<Notification> create(CreateNotificationUseCase.Command command) {
        UUID userId = Guard.notNull(command.userId(), "userId");
        Instant now = clock.instant();
        // Se construye primero para validar la entrada aunque luego se descarte.
        Notification notification = Notification.create(userId, command.title(), command.description(),
                command.priority(), command.type(), command.actionUrl(), command.actionLabel(), command.referenceKey(),
                now);
        NotificationPreferences prefs = preferences.findByUserId(userId)
                .orElseGet(() -> NotificationPreferences.defaults(userId, now));
        ZonedDateTime local = now.atZone(zone);
        long sentToday = notifications.countCreatedSince(userId, local.toLocalDate().atStartOfDay(zone).toInstant());
        DeliveryDecision decision = prefs.evaluate(notification.type(), notification.priority(),
                local.toLocalTime(), sentToday);
        if (!decision.delivered()) {
            return Optional.empty();
        }
        return Optional.of(notifications.save(notification));
    }

    @Override
    public PageResult<Notification> list(ListNotificationsUseCase.Query query) {
        return notifications.findByUser(query.userId(), query.unreadOnly(), query.priority(),
                Guard.notNull(query.page(), "page"));
    }

    @Override
    public UnreadCounts countUnread(UUID userId) {
        return notifications.countUnread(userId);
    }

    @Override
    public Notification markRead(UUID userId, UUID notificationId) {
        Notification notification = own(userId, notificationId);
        notification.markRead(clock.instant());
        return notifications.save(notification);
    }

    @Override
    public int markAllRead(UUID userId) {
        return notifications.markAllRead(userId, clock.instant());
    }

    @Override
    public void delete(UUID userId, UUID notificationId) {
        notifications.delete(own(userId, notificationId).id());
    }

    private Notification own(UUID userId, UUID notificationId) {
        return notifications.findById(notificationId)
                .filter(n -> n.belongsTo(userId))
                .orElseThrow(() -> new NotificationNotFoundException(notificationId));
    }
}
