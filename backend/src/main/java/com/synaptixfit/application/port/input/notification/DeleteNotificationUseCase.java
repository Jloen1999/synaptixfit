package com.synaptixfit.application.port.input.notification;

import java.util.UUID;

/** Borra una notificación propia. */
public interface DeleteNotificationUseCase {

    void delete(UUID userId, UUID notificationId);
}
