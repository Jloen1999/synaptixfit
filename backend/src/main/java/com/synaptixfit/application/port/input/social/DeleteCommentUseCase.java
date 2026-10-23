package com.synaptixfit.application.port.input.social;

import java.util.UUID;

/** Borra (lógicamente) un comentario propio. */
public interface DeleteCommentUseCase {

    void deleteComment(UUID userId, UUID commentId);
}
