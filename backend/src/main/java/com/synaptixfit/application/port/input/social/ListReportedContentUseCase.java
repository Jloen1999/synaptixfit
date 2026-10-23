package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.ReportedContent;
import com.synaptixfit.domain.model.social.ReportedContentType;

/** Contenido reportado pendiente de moderación (administración). */
public interface ListReportedContentUseCase {

    /** {@code type} nulo devuelve publicaciones y comentarios. */
    PageResult<ReportedContent> listReported(ReportedContentType type, PageRequest page);
}
