package com.synaptixfit.domain.port.output.social;

import java.time.Instant;
import java.util.UUID;

/** «Me gusta» de publicaciones (uno por publicación y usuario). */
public interface PostLikeRepositoryPort {

    boolean exists(UUID postId, UUID userId);

    void add(UUID postId, UUID userId, Instant at);

    void remove(UUID postId, UUID userId);

    long countByPost(UUID postId);
}
