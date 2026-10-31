package com.synaptixfit.application.port.input.planner;

import java.util.UUID;

/** Desactiva el enlace de suscripción al calendario (los calendarios externos dejan de verlo). Idempotente. */
public interface RevokeCalendarFeedUseCase {

    void revokeFeed(UUID userId);
}
