package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.ReportedContentType;
import java.util.UUID;

/** Borra un contenido por moderación (administración). Queda auditado. */
public interface RemoveReportedContentUseCase {

    void remove(UUID adminId, ReportedContentType type, UUID contentId);
}
