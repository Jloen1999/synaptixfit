package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.Notification;
import java.util.UUID;

/** Marca una notificación propia como leída. */
public interface MarkNotificationReadUseCase {

    Notification markRead(UUID userId, UUID notificationId);
}
