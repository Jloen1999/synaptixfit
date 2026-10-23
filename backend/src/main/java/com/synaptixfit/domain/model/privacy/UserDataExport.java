package com.synaptixfit.domain.model.privacy;

import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Copia portable (RGPD, art. 20) de todos los datos de un usuario como documento JSON. Las
 * credenciales (hash de contraseña, identificador de Google, tokens) nunca se incluyen.
 */
public record UserDataExport(UUID userId, Instant exportedAt, String json) {

    public UserDataExport {
        Objects.requireNonNull(userId, "userId");
        Objects.requireNonNull(exportedAt, "exportedAt");
        Objects.requireNonNull(json, "json");
    }
}
