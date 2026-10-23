package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.ReportedContentType;
import java.util.UUID;

/** Descarta el reporte de un contenido (administración). Queda auditado. */
public interface DismissReportUseCase {

    void dismiss(UUID adminId, ReportedContentType type, UUID contentId);
}
