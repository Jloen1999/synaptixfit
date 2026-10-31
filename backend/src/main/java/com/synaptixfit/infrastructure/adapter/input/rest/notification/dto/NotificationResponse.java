package com.synaptixfit.infrastructure.adapter.input.rest.notification.dto;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationMessage;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.notification.NotificationType;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Notificación. {@code actionUrl}/{@code actionLabel}: enlace profundo opcional a una ruta del cliente.
 * Con {@code messageCode} el cliente muestra su propio texto (en el idioma elegido) con
 * {@code messageParams}; {@code title} y {@code description} son el respaldo en español.
 */
public record NotificationResponse(UUID id, String title, String description, NotificationPriority priority,
                                   NotificationType type, String actionUrl, String actionLabel, boolean read,
                                   Instant createdAt, Instant readAt, NotificationMessage.Code messageCode,
                                   Map<String, String> messageParams) {

    public static NotificationResponse from(Notification n) {
        NotificationMessage message = n.message();
        return new NotificationResponse(n.id(), n.title(), n.description(), n.priority(), n.type(), n.actionUrl(),
                n.actionLabel(), n.read(), n.createdAt(), n.readAt(), message == null ? null : message.code(),
                message == null ? Map.of() : message.params());
    }
}
