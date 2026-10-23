package com.synaptixfit.domain.port.output.admin;

import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.admin.AuditLogItem;
import com.synaptixfit.domain.model.admin.AuditQuery;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import java.util.UUID;

/** Registro de auditoría administrativa ({@code admin_auditoria}). */
public interface AdminAuditPort {

    void record(AuditEntry entry);

    /** Entradas que cumplen los filtros, de la más reciente a la más antigua. */
    PageResult<AuditLogItem> search(AuditQuery query, PageRequest page);

    /**
     * Sustituye el detalle (antes/después, que puede contener nombre o email) de las entradas
     * que afectan a la entidad por un marcador de redacción. Se usa al anonimizar o eliminar una
     * cuenta: se conserva la traza de qué se hizo y cuándo, pero no los datos personales.
     *
     * @return entradas redactadas
     */
    int redactDetailsForEntity(UUID entityId);
}
