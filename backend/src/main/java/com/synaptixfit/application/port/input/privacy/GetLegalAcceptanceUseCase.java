package com.synaptixfit.application.port.input.privacy;

import java.time.Instant;
import java.util.UUID;

/** Dice si la persona tiene que aceptar la versión vigente de la política y las condiciones. */
public interface GetLegalAcceptanceUseCase {

    /**
     * @param currentVersion  versión vigente
     * @param acceptedVersion última versión aceptada; nula si nunca aceptó
     * @param acceptedAt      cuándo la aceptó; nulo si nunca
     * @param required        hay que pedirle que acepte la vigente
     */
    record Status(String currentVersion, String acceptedVersion, Instant acceptedAt, boolean required) {
    }

    Status getLegalAcceptance(UUID userId);
}
