package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.social.GetPublicProfileUseCase;
import com.synaptixfit.application.port.input.social.SearchUsersUseCase;
import com.synaptixfit.domain.exception.social.SocialUserNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.ContentVisibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.FriendshipRelation;
import com.synaptixfit.domain.model.social.PublicProfile;
import com.synaptixfit.domain.model.social.UserCard;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.UUID;

/** Búsqueda de usuarios y perfil público. */
public class SocialProfileService implements SearchUsersUseCase, GetPublicProfileUseCase {

    private final UserRepositoryPort users;
    private final FriendshipRepositoryPort friendships;
    private final SocialQueryPort queries;

    public SocialProfileService(UserRepositoryPort users, FriendshipRepositoryPort friendships,
                                SocialQueryPort queries) {
        this.users = users;
        this.friendships = friendships;
        this.queries = queries;
    }

    @Override
    public PageResult<UserCard> search(UUID viewerId, String term, PageRequest page) {
        return queries.searchUsers(viewerId, Guard.length(term, "q", 2, 100), page);
    }

    /**
     * Nombre y avatar son visibles para cualquiera que pueda descubrir al usuario; nivel, racha y
     * contadores solo si su privacidad lo permite (si no, {@code restricted = true}).
     */
    @Override
    public PublicProfile getProfile(UUID viewerId, UUID targetUserId) {
        Friendship relation = viewerId.equals(targetUserId)
                ? null : friendships.findBetween(viewerId, targetUserId).orElse(null);
        User target = users.findById(targetUserId)
                .filter(u -> ContentVisibility.canDiscover(viewerId, u, relation))
                .orElseThrow(() -> new SocialUserNotFoundException(targetUserId));
        FriendshipRelation rel = relation == null ? FriendshipRelation.NONE : relation.relationFor(viewerId);
        UUID friendshipId = relation == null || rel == FriendshipRelation.NONE ? null : relation.id();
        if (!ContentVisibility.canView(viewerId, target, relation)) {
            return new PublicProfile(target.id(), target.fullName(), target.avatarUrl(), target.privacy(), true,
                    null, null, null, null, rel, friendshipId);
        }
        return new PublicProfile(target.id(), target.fullName(), target.avatarUrl(), target.privacy(), false,
                target.level(), target.streak(), queries.countPosts(target.id()), queries.countFriends(target.id()),
                rel, friendshipId);
    }
}
