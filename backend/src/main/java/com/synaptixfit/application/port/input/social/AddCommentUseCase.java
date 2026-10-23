package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.CommentView;
import java.util.UUID;

/** Comenta una publicación visible (1-500 caracteres). */
public interface AddCommentUseCase {

    record Command(UUID userId, UUID postId, String text) {}

    CommentView addComment(Command command);
}
