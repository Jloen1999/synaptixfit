package com.synaptixfit.application.port.input.social;

import java.util.UUID;

/** Borra una publicación propia con sus likes y comentarios. */
public interface DeletePostUseCase {

    void deletePost(UUID userId, UUID postId);
}
