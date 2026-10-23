package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.Notification;
import com.synaptixfit.domain.model.notification.NotificationPriority;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Notificaciones del usuario, más recientes primero. */
public interface ListNotificationsUseCase {

    record Query(UUID userId, boolean unreadOnly, NotificationPriority priority, PageRequest page) {}

    PageResult<Notification> list(Query query);
}
