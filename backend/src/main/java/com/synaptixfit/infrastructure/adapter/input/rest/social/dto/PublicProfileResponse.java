package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.badge.BadgeRarity;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.PublicBadge;
import com.synaptixfit.domain.model.social.PublicProfile;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Perfil público. Con {@code restricted = true}, level/streak/postsCount/friendsCount van a null y
 * {@code badges} vacía.
 */
public record PublicProfileResponse(UUID id, String fullName, String avatarUrl, Visibility privacy,
                                    boolean restricted, Integer level, Integer streak, Long postsCount,
                                    Long friendsCount, FriendshipRelation relation, UUID friendshipId,
                                    List<PublicBadgeResponse> badges) {

    public static PublicProfileResponse from(PublicProfile p) {
        return new PublicProfileResponse(p.id(), p.fullName(), p.avatarUrl(), p.privacy(), p.restricted(), p.level(),
                p.streak(), p.postsCount(), p.friendsCount(), p.relation(), p.friendshipId(),
                p.badges().stream().map(PublicBadgeResponse::from).toList());
    }

    /** Insignia que el usuario enseña en su perfil. */
    public record PublicBadgeResponse(UUID id, String name, String description, String icon, BadgeRarity rarity,
                                      Instant earnedAt) {

        static PublicBadgeResponse from(PublicBadge b) {
            return new PublicBadgeResponse(b.id(), b.name(), b.description(), b.icon(), b.rarity(), b.earnedAt());
        }
    }
}
