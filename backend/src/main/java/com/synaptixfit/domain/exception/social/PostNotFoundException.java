package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La publicación no existe o el usuario no puede verla. */
public class PostNotFoundException extends ResourceNotFoundException {

    public PostNotFoundException(UUID id) {
        super("POST_NOT_FOUND", "Post", id);
    }
}
