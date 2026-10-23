package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.LikeStatus;
import java.util.UUID;

/** Estado del «me gusta» tras la operación. */
public record LikeStatusResponse(UUID postId, boolean liked, long likesCount) {

    public static LikeStatusResponse from(LikeStatus s) {
        return new LikeStatusResponse(s.postId(), s.liked(), s.likesCount());
    }
}
