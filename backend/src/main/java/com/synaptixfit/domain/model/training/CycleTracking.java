package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.CycleConsentRequiredException;
import java.time.Instant;

/**
 * Si el seguimiento del ciclo está activo y cuándo se dio el consentimiento (ADR 0033). Está apagado por
 * defecto para todo el mundo: solo lo activa quien quiere, aceptando para qué se usan esos datos.
 */
public record CycleTracking(boolean enabled, Instant consentedAt) {

    public static final CycleTracking OFF = new CycleTracking(false, null);

    /** Activar exige el consentimiento explícito; se guarda cuándo se dio. */
    public static CycleTracking enable(boolean consent, Instant now) {
        if (!consent) {
            throw new CycleConsentRequiredException();
        }
        return new CycleTracking(true, now);
    }
}
