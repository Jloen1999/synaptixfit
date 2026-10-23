package com.synaptixfit.infrastructure.adapter.input.rest.social.dto;

import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.PublicProfile;
import java.util.UUID;

/** Perfil público. Con {@code restricted = true}, level/streak/postsCount/friendsCount van a null. */
public record PublicProfileResponse(UUID id, String fullName, String avatarUrl, Visibility privacy,
                                    boolean restricted, Integer level, Integer streak, Long postsCount,
                                    Long friendsCount, FriendshipRelation relation, UUID friendshipId) {

    public static PublicProfileResponse from(PublicProfile p) {
        return new PublicProfileResponse(p.id(), p.fullName(), p.avatarUrl(), p.privacy(), p.restricted(), p.level(),
                p.streak(), p.postsCount(), p.friendsCount(), p.relation(), p.friendshipId());
    }
}
