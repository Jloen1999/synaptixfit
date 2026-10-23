package com.synaptixfit.domain.port.output.social;

import java.util.Map;
import java.util.UUID;

/** Registro de auditoría de las acciones de moderación ({@code admin_auditoria}). */
public interface ModerationAuditPort {

    void record(UUID adminId, String action, String entity, UUID entityId, Map<String, String> detail);
}
