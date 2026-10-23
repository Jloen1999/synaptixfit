package com.synaptixfit.domain.exception.notification;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Las horas de silencio deben indicarse juntas (inicio y fin) y ser distintas. */
public class NotificationInvalidQuietHoursException extends InvalidInputException {

    public NotificationInvalidQuietHoursException() {
        super("NOTIFICATION_INVALID_QUIET_HOURS", "Quiet hours need both start and end, and they must differ");
    }
}
