package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.user.User;
import java.time.Instant;
import java.util.UUID;

/** Relación vista por un usuario, con los datos del otro. */
public record FriendshipView(UUID id, FriendshipStatus status, FriendshipRelation relation, UUID userId,
                             String fullName, String avatarUrl, int level, Instant createdAt, Instant updatedAt) {

    public static FriendshipView of(Friendship f, UUID viewerId, User other) {
        return new FriendshipView(f.id(), f.status(), f.relationFor(viewerId), other.id(), other.fullName(),
                other.avatarUrl(), other.level(), f.createdAt(), f.updatedAt());
    }
}
