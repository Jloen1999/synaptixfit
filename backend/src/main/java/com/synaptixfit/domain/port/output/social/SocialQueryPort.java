package com.synaptixfit.domain.port.output.social;

import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.CommentView;
import com.synaptixfit.domain.model.social.FeedQuery;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.domain.model.social.FriendshipView;
import com.synaptixfit.domain.model.social.PostView;
import com.synaptixfit.domain.model.social.PublicBadge;
import com.synaptixfit.domain.model.social.UserCard;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Lecturas compuestas del módulo social (muro, comentarios, búsquedas), resueltas en una sola
 * consulta por página para evitar N+1.
 */
public interface SocialQueryPort {

    /**
     * Página del muro ordenada por fecha descendente, aplicando las reglas de
     * {@link com.synaptixfit.domain.model.social.ContentVisibility}.
     */
    PageResult<PostView> feed(FeedQuery query);

    /** Una publicación con contadores, sin comprobar visibilidad (la comprueba el servicio). */
    Optional<PostView> findPost(UUID viewerId, UUID postId);

    /** Comentarios no borrados de una publicación, del más antiguo al más reciente. */
    PageResult<CommentView> comments(UUID viewerId, UUID postId, PageRequest page);

    Optional<CommentView> findComment(UUID commentId);

    /** Usuarios descubribles cuyo nombre contiene {@code term}. */
    PageResult<UserCard> searchUsers(UUID viewerId, String term, PageRequest page);

    PageResult<FriendshipView> friendships(UUID viewerId, FriendshipListKind kind, PageRequest page);

    long countPosts(UUID authorId);

    long countFriends(UUID userId);

    /** Insignias ganadas que el usuario deja ver en su perfil (sin orden: lo decide el servicio). */
    List<PublicBadge> visibleBadges(UUID userId);
}
