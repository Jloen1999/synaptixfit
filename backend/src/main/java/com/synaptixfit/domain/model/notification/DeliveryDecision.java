package com.synaptixfit.domain.model.notification;

/** Resultado de evaluar las preferencias del receptor antes de crear una notificación. */
public enum DeliveryDecision {
    DELIVER,
    SUPPRESSED_CATEGORY,
    SUPPRESSED_MODE,
    SUPPRESSED_QUIET_HOURS,
    SUPPRESSED_DAILY_LIMIT;

    public boolean delivered() {
        return this == DELIVER;
    }
}
