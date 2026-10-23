package com.synaptixfit.domain.port.output.privacy;

import java.time.Instant;
import java.util.UUID;

/** Lectura de todos los datos de un usuario como un documento JSON (RGPD, portabilidad). */
public interface UserDataExportPort {

    String exportAsJson(UUID userId, Instant exportedAt);
}
