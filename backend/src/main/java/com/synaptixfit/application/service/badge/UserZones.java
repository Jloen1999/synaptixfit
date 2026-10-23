package com.synaptixfit.application.service.badge;

import com.synaptixfit.domain.exception.badge.InvalidTimeZoneException;
import java.time.DateTimeException;
import java.time.ZoneId;

/** Resuelve la zona horaria del usuario (las rachas dependen de su día local). */
final class UserZones {

    private UserZones() {
    }

    static ZoneId resolve(String zone, ZoneId fallback) {
        if (zone == null || zone.isBlank()) {
            return fallback;
        }
        try {
            return ZoneId.of(zone.strip());
        } catch (DateTimeException e) {
            throw new InvalidTimeZoneException(zone);
        }
    }
}
