package com.synaptixfit.domain.port.output.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.ReportedContent;
import com.synaptixfit.domain.model.social.ReportedContentType;

/** Contenido reportado (publicaciones y comentarios) en una sola lista paginada. */
public interface ReportedContentQueryPort {

    /** @param type filtra por tipo; {@code null} para ambos */
    PageResult<ReportedContent> findReported(ReportedContentType type, PageRequest page);
}
