package com.synaptixfit.application.port.input.social;

import java.util.UUID;

/** Reporta un comentario ajeno visible para moderación. */
public interface ReportCommentUseCase {

    void reportComment(UUID userId, UUID commentId);
}
