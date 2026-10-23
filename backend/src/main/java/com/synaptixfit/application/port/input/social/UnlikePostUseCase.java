package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.LikeStatus;
import java.util.UUID;

/** Quita el «me gusta» de una publicación. Idempotente. */
public interface UnlikePostUseCase {

    LikeStatus unlike(UUID userId, UUID postId);
}
