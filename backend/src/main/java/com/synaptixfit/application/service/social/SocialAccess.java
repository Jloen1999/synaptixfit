package com.synaptixfit.application.service.social;

import com.synaptixfit.domain.exception.social.PostNotFoundException;
import com.synaptixfit.domain.model.social.ContentVisibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.UUID;

/**
 * Comprobaciones de acceso compartidas por los servicios sociales. Carga autor y relación y
 * delega la decisión en {@link ContentVisibility}.
 */
public final class SocialAccess {

    private final PostRepositoryPort posts;
    private final UserRepositoryPort users;
    private final FriendshipRepositoryPort friendships;

    public SocialAccess(PostRepositoryPort posts, UserRepositoryPort users, FriendshipRepositoryPort friendships) {
        this.posts = posts;
        this.users = users;
        this.friendships = friendships;
    }

    /** Publicación visible para {@code viewerId}; si no existe o no puede verla, 404. */
    public Post visiblePost(UUID viewerId, UUID postId) {
        Post post = posts.findById(postId).orElseThrow(() -> new PostNotFoundException(postId));
        if (!canViewContentOf(viewerId, post.authorId())) {
            throw new PostNotFoundException(postId);
        }
        return post;
    }

    /** ¿Puede {@code viewerId} ver las publicaciones de {@code authorId}? */
    public boolean canViewContentOf(UUID viewerId, UUID authorId) {
        if (viewerId.equals(authorId)) {
            return true;
        }
        User author = users.findById(authorId).orElse(null);
        return author != null && ContentVisibility.canView(viewerId, author, relation(viewerId, authorId));
    }

    /**
     * ¿Ve {@code viewerId} las interacciones (comentarios) de {@code authorId}? Aquí no cuenta la
     * privacidad del perfil, solo shadowban, cuenta eliminada y bloqueos.
     */
    public boolean canSeeInteractionsOf(UUID viewerId, UUID authorId) {
        if (viewerId.equals(authorId)) {
            return true;
        }
        User author = users.findById(authorId).orElse(null);
        if (author == null || !author.isActive() || author.shadowbanned()) {
            return false;
        }
        Friendship relation = relation(viewerId, authorId);
        return relation == null || !relation.isBlocked();
    }

    private Friendship relation(UUID a, UUID b) {
        return friendships.findBetween(a, b).orElse(null);
    }
}
