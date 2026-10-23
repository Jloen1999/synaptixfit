package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import java.time.Instant;
import java.util.UUID;

/** Notificación. {@code actionUrl}/{@code actionLabel}: enlace profundo opcional a una ruta del cliente. */
public record NotificationResponse(UUID id, String title, String description, NotificationPriority priority,
                                   NotificationType type, String actionUrl, String actionLabel, boolean read,
                                   Instant createdAt, Instant readAt) {

    public static NotificationResponse from(Notification n) {
        return new NotificationResponse(n.id(), n.title(), n.description(), n.priority(), n.type(), n.actionUrl(),
                n.actionLabel(), n.read(), n.createdAt(), n.readAt());
    }
}
