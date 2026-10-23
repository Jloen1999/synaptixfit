package com.synaptixfit.application.service.admin;

import com.synaptixfit.application.port.input.admin.RecordAdminAuditUseCase;
import com.synaptixfit.application.port.input.admin.SearchAuditLogUseCase;
import com.synaptixfit.domain.model.admin.AuditEntry;
import com.synaptixfit.domain.model.admin.AuditLogItem;
import com.synaptixfit.domain.model.admin.AuditQuery;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.port.output.admin.AdminAuditPort;
import java.time.Clock;

/** Consulta y registro de la auditoría administrativa. */
public class AdminAuditService implements SearchAuditLogUseCase, RecordAdminAuditUseCase {

    private final AdminAuditPort audit;
    private final Clock clock;

    public AdminAuditService(AdminAuditPort audit, Clock clock) {
        this.audit = audit;
        this.clock = clock;
    }

    @Override
    public PageResult<AuditLogItem> searchAuditLog(AuditQuery query, PageRequest page) {
        return audit.search(query, page);
    }

    @Override
    public void recordAdminAudit(Command command) {
        audit.record(AuditEntry.of(command.adminId(), command.action(), command.entity(), command.entityId(),
                command.details(), clock.instant()));
    }
}
