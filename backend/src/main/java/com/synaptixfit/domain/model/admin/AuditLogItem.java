package com.synaptixfit.domain.model.admin;

/** Entrada de auditoría con los datos visibles del administrador que la hizo (si sigue existiendo). */
public record AuditLogItem(AuditEntry entry, String adminName, String adminEmail) {
}
