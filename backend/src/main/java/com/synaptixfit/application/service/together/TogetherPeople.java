package com.synaptixfit.application.service.together;

import com.synaptixfit.domain.exception.together.TogetherNotFriendsException;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.together.Person;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Quién puede entrar en lo compartido con amigos y cómo se le enseña (ADR 0044): solo amigos mutuos (amistad
 * aceptada, sin bloqueo y con la cuenta activa), y de cada persona solo el nombre y la foto.
 */
public final class TogetherPeople {

    private final FriendshipRepositoryPort friendships;
    private final UserRepositoryPort users;

    public TogetherPeople(FriendshipRepositoryPort friendships, UserRepositoryPort users) {
        this.friendships = friendships;
        this.users = users;
    }

    /** Todos son amigos mutuos de {@code userId}; si no, ninguno se invita. */
    void ensureFriends(UUID userId, Collection<UUID> others) {
        for (UUID other : others) {
            if (other.equals(userId)) {
                continue;
            }
            boolean friends = friendships.findBetween(userId, other).map(Friendship::isAccepted).orElse(false)
                    && users.findById(other).map(User::isActive).orElse(false);
            if (!friends) {
                throw new TogetherNotFriendsException(other);
            }
        }
    }

    /**
     * ¿Puede {@code userId} estar con quien creó algo y con los que están dentro? Amigo mutuo del dueño y sin bloqueo
     * con ninguno de dentro (los invitados no tienen por qué ser amigos entre sí, pero un bloqueo los separa).
     */
    boolean canJoin(UUID userId, UUID ownerId, Collection<UUID> joinedIds) {
        if (!userId.equals(ownerId) && !friendships.findBetween(userId, ownerId).map(Friendship::isAccepted)
                .orElse(false)) {
            return false;
        }
        return joinedIds.stream().filter(id -> !id.equals(userId))
                .noneMatch(id -> friendships.findBetween(userId, id).map(Friendship::isBlocked).orElse(false));
    }

    /** Nombre y foto de cada persona (una cuenta eliminada sale sin nombre). */
    Lookup lookup() {
        return new Lookup();
    }

    /** Caché de una petición: cada persona se lee una vez. */
    final class Lookup {

        private final Map<UUID, Person> cache = new HashMap<>();

        Person of(UUID id) {
            return cache.computeIfAbsent(id, key -> users.findById(key)
                    .filter(User::isActive)
                    .map(u -> new Person(u.id(), u.fullName(), u.avatarUrl()))
                    .orElse(new Person(key, null, null)));
        }
    }
}
