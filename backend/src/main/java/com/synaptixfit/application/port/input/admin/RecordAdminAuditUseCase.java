package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import java.util.Map;
import java.util.UUID;

/**
 * Registra una acción administrativa. Lo usan otros módulos con acciones de administración
 * (moderación de contenido, catálogo de ejercicios) para que toda la auditoría quede en un sitio.
 */
public interface RecordAdminAuditUseCase {

    record Command(UUID adminId, AuditAction action, AuditEntity entity, UUID entityId,
                   Map<String, Object> details) {}

    void recordAdminAudit(Command command);
}
