package com.synaptixfit.application.port.input.notification;

import com.synaptixfit.domain.model.notification.UnreadCounts;
import java.util.UUID;

/** Contador de no leídas por prioridad. */
public interface CountUnreadNotificationsUseCase {

    UnreadCounts countUnread(UUID userId);
}
