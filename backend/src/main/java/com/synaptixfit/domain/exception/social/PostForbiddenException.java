package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ForbiddenOperationException;
import java.util.UUID;

/** Solo el autor puede editar o borrar su publicación. */
public class PostForbiddenException extends ForbiddenOperationException {

    public PostForbiddenException(UUID id) {
        super("POST_FORBIDDEN", "Only the author can modify post " + id);
    }
}
