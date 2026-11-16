package com.synaptixfit.application.port.input.training;

import java.time.Instant;
import java.util.UUID;

/** Si la persona ha dado el consentimiento para el registro diario y cuándo. */
public interface GetHealthConsentUseCase {

    /**
     * {@code outdated}: está dado, pero con un texto anterior al que se enseña hoy (ADR 0054); la app ofrece
     * aceptar el nuevo, sin obligar.
     */
    record Status(boolean given, Instant givenAt, Instant withdrawnAt, boolean outdated) {}

    Status getHealthConsent(UUID userId);
}
