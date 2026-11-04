package com.synaptixfit.domain.model.privacy;

import com.synaptixfit.domain.model.shared.Guard;
import java.time.Instant;
import java.util.UUID;

/** Constancia de que una persona aceptó una versión de la política y las condiciones, y cuándo (ADR 0034). */
public record LegalAcceptance(UUID userId, String version, Instant acceptedAt) {

    public LegalAcceptance {
        Guard.notNull(userId, "userId");
        version = Guard.notBlank(version, "version");
        Guard.notNull(acceptedAt, "acceptedAt");
    }
}
