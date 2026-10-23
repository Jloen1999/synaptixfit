package com.synaptixfit.domain.exception.notification;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La notificación no existe o no pertenece al usuario. */
public class NotificationNotFoundException extends ResourceNotFoundException {

    public NotificationNotFoundException(UUID id) {
        super("NOTIFICATION_NOT_FOUND", "Notification", id);
    }
}
