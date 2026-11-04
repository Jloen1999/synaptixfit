package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;

import java.time.Instant;
import java.util.UUID;

/**
 * Consentimiento expreso para guardar el registro diario (sueño, energía, agujetas, dolor), que son datos de salud
 * (art. 9 RGPD, ADR 0034). Se da aparte de aceptar la política y se puede retirar; retirarlo deja de usar los
 * registros a partir de ese momento.
 */
public record HealthConsent(UUID userId, Instant givenAt, Instant withdrawnAt) {

    public HealthConsent {
        Guard.notNull(userId, "userId");
        Guard.notNull(givenAt, "givenAt");
    }

    public static HealthConsent give(UUID userId, Instant now) {
        return new HealthConsent(userId, now, null);
    }

    public HealthConsent withdraw(Instant now) {
        return new HealthConsent(userId, givenAt, now);
    }

    /** Dado y no retirado. */
    public boolean active() {
        return withdrawnAt == null;
    }
}
