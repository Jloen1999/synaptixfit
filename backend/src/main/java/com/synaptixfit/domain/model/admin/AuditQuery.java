package com.synaptixfit.domain.model.admin;

import com.synaptixfit.domain.exception.admin.AdminInvalidDateRangeException;
import java.time.Instant;
import java.util.UUID;

/**
 * Filtros del listado de auditoría. Los nulos no filtran; {@code from} es inclusivo y {@code to}
 * exclusivo.
 */
public record AuditQuery(UUID adminId, AuditAction action, AuditEntity entity, UUID entityId,
                         Instant from, Instant to) {

    public AuditQuery {
        if (from != null && to != null && !from.isBefore(to)) {
            throw new AdminInvalidDateRangeException();
        }
    }
}
