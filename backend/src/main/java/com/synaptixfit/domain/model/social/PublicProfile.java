package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;

/**
 * Perfil público de un usuario. Si {@code restricted} es verdadero, quien mira no tiene acceso
 * por la privacidad del perfil y los datos de actividad van a {@code null}.
 */
public record PublicProfile(UUID id, String fullName, String avatarUrl, Visibility privacy, boolean restricted,
                            Integer level, Integer streak, Long postsCount, Long friendsCount,
                            FriendshipRelation relation, UUID friendshipId) {
}
