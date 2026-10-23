package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El comentario no existe, está borrado o el usuario no puede verlo. */
public class CommentNotFoundException extends ResourceNotFoundException {

    public CommentNotFoundException(UUID id) {
        super("COMMENT_NOT_FOUND", "Comment", id);
    }
}
