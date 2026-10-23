package com.synaptixfit.application.port.input.admin;

import com.synaptixfit.domain.model.admin.AuditLogItem;
import com.synaptixfit.domain.model.admin.AuditQuery;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;

/** Listado paginado y filtrable de la auditoría. */
public interface SearchAuditLogUseCase {

    PageResult<AuditLogItem> searchAuditLog(AuditQuery query, PageRequest page);
}
