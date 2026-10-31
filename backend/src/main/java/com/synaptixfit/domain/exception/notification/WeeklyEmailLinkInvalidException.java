package com.synaptixfit.domain.exception.notification;

import com.synaptixfit.domain.exception.NotFoundException;

/** El enlace de confirmación o de baja del resumen semanal no existe o ya no sirve. */
public class WeeklyEmailLinkInvalidException extends NotFoundException {

    public WeeklyEmailLinkInvalidException() {
        super("NOTIFICATION_WEEKLY_EMAIL_LINK_INVALID", "Weekly email link is invalid or no longer valid");
    }
}
