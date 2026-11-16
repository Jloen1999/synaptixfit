package com.synaptixfit.infrastructure.adapter.input.rest.training.dto;

import com.synaptixfit.application.port.input.training.GetHealthConsentUseCase;
import java.time.Instant;

/**
 * Estado del consentimiento para el registro diario. {@code outdated}: dado con un texto anterior (ADR 0054), la app
 * ofrece aceptar el texto nuevo.
 */
public record HealthConsentResponse(boolean given, Instant givenAt, Instant withdrawnAt, boolean outdated) {

    public static HealthConsentResponse from(GetHealthConsentUseCase.Status status) {
        return new HealthConsentResponse(status.given(), status.givenAt(), status.withdrawnAt(), status.outdated());
    }
}
