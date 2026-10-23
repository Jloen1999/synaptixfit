package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.LikeStatus;
import java.util.UUID;

/** Da «me gusta» a una publicación visible. Idempotente. */
public interface LikePostUseCase {

    LikeStatus like(UUID userId, UUID postId);
}
