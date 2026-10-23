package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.FriendshipStatus;
import com.synaptixfit.domain.model.social.FriendshipView;
import java.time.Instant;
import java.util.UUID;

/** Relación con otro usuario; {@code relation} es el estado visto por el usuario actual. */
public record FriendshipResponse(UUID id, FriendshipStatus status, FriendshipRelation relation,
                                 SocialUserResponse user, Instant createdAt, Instant updatedAt) {

    public static FriendshipResponse from(FriendshipView f) {
        return new FriendshipResponse(f.id(), f.status(), f.relation(),
                new SocialUserResponse(f.userId(), f.fullName(), f.avatarUrl(), f.level()), f.createdAt(),
                f.updatedAt());
    }
}
