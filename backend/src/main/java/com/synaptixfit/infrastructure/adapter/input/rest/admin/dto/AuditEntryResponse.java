package com.synaptixfit.infrastructure.adapter.input.rest.admin.dto;

import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditLogItem;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Entrada de auditoría. {@code details} suele tener {@code before}/{@code after}; tras anonimizar o
 * eliminar la cuenta afectada queda como {@code {"redacted": true}}.
 */
public record AuditEntryResponse(UUID id, UUID adminId, String adminName, String adminEmail, AuditAction action,
                                 AuditEntity entityType, UUID entityId, Map<String, Object> details,
                                 Instant createdAt) {

    public static AuditEntryResponse from(AuditLogItem item) {
        var e = item.entry();
        return new AuditEntryResponse(e.id(), e.adminId(), item.adminName(), item.adminEmail(), e.action(),
                e.entity(), e.entityId(), e.details(), e.createdAt());
    }
}
