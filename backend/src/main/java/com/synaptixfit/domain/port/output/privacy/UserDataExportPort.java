package com.synaptixfit.domain.port.output.privacy;

import java.time.Instant;
import java.util.UUID;

/**
 * Lectura de todos los datos de un usuario como un documento JSON (RGPD, portabilidad). Los datos de salud (ciclo,
 * ADR 0033) solo van en la copia que pide su dueño, nunca en la que pide un administrador.
 */
public interface UserDataExportPort {

    /** Quién pide la copia: decide si llevan los datos de salud. */
    enum Requester {
        OWNER,
        ADMINISTRATOR;

        public boolean includesHealthData() {
            return this == OWNER;
        }
    }

    String exportAsJson(UUID userId, Instant exportedAt, Requester requester);
}
