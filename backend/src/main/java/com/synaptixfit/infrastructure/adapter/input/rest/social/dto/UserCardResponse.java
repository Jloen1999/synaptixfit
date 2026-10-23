package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.UserCard;
import java.util.UUID;

/** Resultado de búsqueda de usuarios. {@code friendshipId} es nulo si {@code relation} es NONE. */
public record UserCardResponse(UUID id, String fullName, String avatarUrl, int level, FriendshipRelation relation,
                               UUID friendshipId) {

    public static UserCardResponse from(UserCard u) {
        return new UserCardResponse(u.id(), u.fullName(), u.avatarUrl(), u.level(), u.relation(), u.friendshipId());
    }
}
