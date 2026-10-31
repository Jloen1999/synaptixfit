package com.synaptixfit.domain.exception.planner;

import com.synaptixfit.domain.exception.NotFoundException;

/** El enlace de suscripción no existe o se revocó (se creó otro o se desactivó). */
public class CalendarFeedNotFoundException extends NotFoundException {

    public CalendarFeedNotFoundException() {
        super("PLANNER_CALENDAR_FEED_NOT_FOUND", "Calendar feed not found or revoked");
    }
}
