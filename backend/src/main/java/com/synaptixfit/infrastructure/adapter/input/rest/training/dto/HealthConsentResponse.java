package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.GetHealthConsentUseCase;
import java.time.Instant;

/** Estado del consentimiento para el registro diario. */
public record HealthConsentResponse(boolean given, Instant givenAt, Instant withdrawnAt) {

    public static HealthConsentResponse from(GetHealthConsentUseCase.Status status) {
        return new HealthConsentResponse(status.given(), status.givenAt(), status.withdrawnAt());
    }
}
