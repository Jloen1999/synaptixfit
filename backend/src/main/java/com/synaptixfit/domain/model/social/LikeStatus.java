package com.synaptixfit.domain.model.social;

import java.util.UUID;

/** Estado del «me gusta» de un usuario sobre una publicación tras la operación. */
public record LikeStatus(UUID postId, boolean liked, long likesCount) {
}
