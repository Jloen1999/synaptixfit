package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.exception.training.CycleConsentRequiredException;
import java.time.Instant;

/**
 * Si el seguimiento del ciclo está activo, cuándo se dio el consentimiento y, si se desactivó, cuándo se retiró
 * (ADR 0033). Está apagado por defecto para todo el mundo: solo lo activa quien quiere, aceptando para qué se usan
 * esos datos.
 */
public record CycleTracking(boolean enabled, Instant consentedAt, Instant withdrawnAt) {

    public static final CycleTracking OFF = new CycleTracking(false, null, null);

    /** Activar exige el consentimiento explícito; se guarda cuándo se dio. */
    public static CycleTracking enable(boolean consent, Instant now) {
        if (!consent) {
            throw new CycleConsentRequiredException();
        }
        return new CycleTracking(true, now, null);
    }

    /** Desactivar retira el consentimiento: se conserva cuándo se dio y se apunta cuándo se retiró. */
    public CycleTracking disable(Instant now) {
        return enabled ? new CycleTracking(false, consentedAt, now) : this;
    }
}
