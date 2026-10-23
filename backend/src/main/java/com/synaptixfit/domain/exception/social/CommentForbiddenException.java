package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ForbiddenOperationException;
import java.util.UUID;

/** Solo el autor puede editar o borrar su comentario. */
public class CommentForbiddenException extends ForbiddenOperationException {

    public CommentForbiddenException(UUID id) {
        super("COMMENT_FORBIDDEN", "Only the author can modify comment " + id);
    }
}
