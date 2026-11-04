package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.shared.Visibility;
import java.util.List;
import java.util.UUID;

/**
 * Perfil público de un usuario. Si {@code restricted} es verdadero, quien mira no tiene acceso
 * por la privacidad del perfil y los datos de actividad van a {@code null} (y {@code badges} vacía).
 */
public record PublicProfile(UUID id, String fullName, String avatarUrl, Visibility privacy, boolean restricted,
                            Integer level, Integer streak, Long postsCount, Long friendsCount,
                            FriendshipRelation relation, UUID friendshipId, List<PublicBadge> badges) {

    public PublicProfile {
        badges = badges == null ? List.of() : List.copyOf(badges);
    }
}
