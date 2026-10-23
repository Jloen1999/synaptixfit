package com.synaptixfit.domain.model.social;

import java.util.UUID;

/** Resultado de búsqueda de usuarios con su relación respecto a quien busca. */
public record UserCard(UUID id, String fullName, String avatarUrl, int level, FriendshipRelation relation,
                       UUID friendshipId) {
}
