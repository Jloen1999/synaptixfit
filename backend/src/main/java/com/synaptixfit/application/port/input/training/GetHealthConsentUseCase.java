package com.synaptixfit.application.port.input.training;

import java.time.Instant;
import java.util.UUID;

/** Si la persona ha dado el consentimiento para el registro diario y cuándo. */
public interface GetHealthConsentUseCase {

    record Status(boolean given, Instant givenAt, Instant withdrawnAt) {}

    Status getHealthConsent(UUID userId);
}
