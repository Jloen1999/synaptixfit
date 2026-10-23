package com.synaptixfit.infrastructure.adapter.input.rest.admin;

import com.synaptixfit.application.port.input.admin.SearchAuditLogUseCase;
import com.synaptixfit.domain.model.admin.AuditAction;
import com.synaptixfit.domain.model.admin.AuditEntity;
import com.synaptixfit.domain.model.admin.AuditQuery;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.admin.dto.AuditEntryResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.support.PageResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Instant;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Registro de auditoría de las acciones administrativas. */
@Tag(name = "Admin - Audit")
@RestController
@RequestMapping("/api/v1/admin/audit")
public class AdminAuditController {

    private final SearchAuditLogUseCase searchAuditLog;

    public AdminAuditController(SearchAuditLogUseCase searchAuditLog) {
        this.searchAuditLog = searchAuditLog;
    }

    @GetMapping
    public PageResponse<AuditEntryResponse> search(@RequestParam(required = false) UUID adminId,
                                                   @RequestParam(required = false) AuditAction action,
                                                   @RequestParam(required = false) AuditEntity entityType,
                                                   @RequestParam(required = false) UUID entityId,
                                                   @RequestParam(required = false) Instant from,
                                                   @RequestParam(required = false) Instant to,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        AuditQuery query = new AuditQuery(adminId, action, entityType, entityId, from, to);
        return PageResponse.from(searchAuditLog.searchAuditLog(query, new PageRequest(page, size)),
                AuditEntryResponse::from);
    }
}
