package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.CommentView;
import java.util.UUID;

/** Edita un comentario propio. */
public interface EditCommentUseCase {

    record Command(UUID userId, UUID commentId, String text) {}

    CommentView editComment(Command command);
}
