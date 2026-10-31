package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ConflictException;

/** Ya hay una publicación del mismo tipo vinculada a la misma entidad (p. ej. esa sesión de entrenamiento). */
public class PostAlreadySharedException extends ConflictException {

    public PostAlreadySharedException() {
        super("POST_ALREADY_SHARED", "This item has already been shared");
    }
}
