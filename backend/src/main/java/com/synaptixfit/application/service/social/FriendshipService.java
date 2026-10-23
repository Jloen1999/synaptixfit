package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.AcceptFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.BlockUserUseCase;
import com.synaptixfit.application.port.input.social.ListFriendshipsUseCase;
import com.synaptixfit.application.port.input.social.RejectFriendRequestUseCase;
import com.synaptixfit.application.port.input.social.RemoveFriendshipUseCase;
import com.synaptixfit.application.port.input.social.SendFriendRequestUseCase;
import com.synaptixfit.domain.exception.social.FriendshipAlreadyExistsException;
import com.synaptixfit.domain.exception.social.FriendshipBlockedException;
import com.synaptixfit.domain.exception.social.FriendshipNotFoundException;
import com.synaptixfit.domain.exception.social.FriendshipSelfTargetException;
import com.synaptixfit.domain.exception.social.SocialUserNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.ContentVisibility;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.FriendshipListKind;
import com.synaptixfit.domain.model.social.FriendshipView;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.social.SocialQueryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

/** Solicitudes de amistad, amistades y bloqueos. */
public class FriendshipService implements SendFriendRequestUseCase, AcceptFriendRequestUseCase,
        RejectFriendRequestUseCase, BlockUserUseCase, RemoveFriendshipUseCase, ListFriendshipsUseCase {

    private final FriendshipRepositoryPort friendships;
    private final UserRepositoryPort users;
    private final SocialQueryPort queries;
    private final SocialNotifier notifier;
    private final Clock clock;

    public FriendshipService(FriendshipRepositoryPort friendships, UserRepositoryPort users, SocialQueryPort queries,
                             CreateNotificationUseCase notifications, Clock clock) {
        this.friendships = friendships;
        this.users = users;
        this.queries = queries;
        this.notifier = new SocialNotifier(notifications, users);
        this.clock = clock;
    }

    /**
     * Envía una solicitud. Casos según la relación existente: ninguna o rechazada → nueva solicitud;
     * pendiente recibida → se acepta (petición mutua); aceptada o pendiente enviada → conflicto;
     * bloqueo propio → hay que desbloquear; bloqueo ajeno → el usuario no existe para quien pide.
     */
    @Override
    public FriendshipView sendRequest(UUID requesterId, UUID addresseeId) {
        if (requesterId.equals(addresseeId)) {
            throw new FriendshipSelfTargetException(requesterId);
        }
        Instant now = clock.instant();
        Friendship existing = friendships.findBetween(requesterId, addresseeId).orElse(null);
        User addressee = discoverableUser(requesterId, addresseeId, existing);
        Friendship result;
        if (existing == null) {
            result = friendships.save(Friendship.request(requesterId, addresseeId, now));
            notifier.friendRequestReceived(addresseeId, requesterId);
        } else {
            switch (existing.status()) {
                case BLOCKED -> throw new FriendshipBlockedException(addresseeId);
                case ACCEPTED -> throw new FriendshipAlreadyExistsException(addresseeId);
                case PENDING -> {
                    if (existing.requesterId().equals(requesterId)) {
                        throw new FriendshipAlreadyExistsException(addresseeId);
                    }
                    existing.accept(requesterId, now);
                    result = friendships.save(existing);
                    notifier.friendRequestAccepted(addresseeId, requesterId);
                }
                case REJECTED -> {
                    existing.renewRequest(requesterId, now);
                    result = friendships.save(existing);
                    notifier.friendRequestReceived(addresseeId, requesterId);
                }
                default -> throw new IllegalStateException("Unknown status " + existing.status());
            }
        }
        return FriendshipView.of(result, requesterId, addressee);
    }

    @Override
    public FriendshipView accept(UUID userId, UUID friendshipId) {
        Friendship friendship = visible(userId, friendshipId);
        friendship.accept(userId, clock.instant());
        Friendship saved = friendships.save(friendship);
        notifier.friendRequestAccepted(saved.requesterId(), userId);
        return view(saved, userId);
    }

    @Override
    public FriendshipView reject(UUID userId, UUID friendshipId) {
        Friendship friendship = visible(userId, friendshipId);
        friendship.reject(userId, clock.instant());
        return view(friendships.save(friendship), userId);
    }

    @Override
    public FriendshipView block(UUID userId, UUID targetUserId) {
        if (userId.equals(targetUserId)) {
            throw new FriendshipSelfTargetException(userId);
        }
        Instant now = clock.instant();
        Friendship existing = friendships.findBetween(userId, targetUserId).orElse(null);
        User target = users.findById(targetUserId)
                .filter(User::isActive)
                .orElseThrow(() -> new SocialUserNotFoundException(targetUserId));
        if (existing != null && existing.isBlocked() && !existing.isBlockedBy(userId)) {
            // Ya nos ha bloqueado: para nosotros no existe.
            throw new SocialUserNotFoundException(targetUserId);
        }
        Friendship result;
        if (existing == null) {
            result = Friendship.blocking(userId, targetUserId, now);
        } else {
            existing.blockBy(userId, now);
            result = existing;
        }
        return FriendshipView.of(friendships.save(result), userId, target);
    }

    @Override
    public void remove(UUID userId, UUID friendshipId) {
        Friendship friendship = friendships.findById(friendshipId)
                .orElseThrow(() -> new FriendshipNotFoundException(friendshipId));
        friendship.ensureRemovableBy(userId);
        friendships.delete(friendship.id());
    }

    @Override
    public PageResult<FriendshipView> list(UUID userId, FriendshipListKind kind, PageRequest page) {
        return queries.friendships(userId, Guard.notNull(kind, "kind"), page);
    }

    private User discoverableUser(UUID viewerId, UUID targetId, Friendship relation) {
        return users.findById(targetId)
                .filter(u -> ContentVisibility.canDiscover(viewerId, u, relation))
                .orElseThrow(() -> new SocialUserNotFoundException(targetId));
    }

    private Friendship visible(UUID userId, UUID friendshipId) {
        return friendships.findById(friendshipId)
                .filter(f -> f.isVisibleTo(userId))
                .orElseThrow(() -> new FriendshipNotFoundException(friendshipId));
    }

    private FriendshipView view(Friendship friendship, UUID viewerId) {
        UUID otherId = friendship.otherThan(viewerId);
        User other = users.findById(otherId).orElseThrow(() -> new SocialUserNotFoundException(otherId));
        return FriendshipView.of(friendship, viewerId, other);
    }
}
