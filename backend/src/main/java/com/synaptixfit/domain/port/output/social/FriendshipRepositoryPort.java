package com.synaptixfit.domain.port.output.social;

import com.synaptixfit.domain.model.social.Friendship;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de relaciones entre usuarios. */
public interface FriendshipRepositoryPort {

    Optional<Friendship> findById(UUID id);

    /** Relación entre dos usuarios en cualquier sentido. */
    Optional<Friendship> findBetween(UUID userA, UUID userB);

    Friendship save(Friendship friendship);

    void delete(UUID id);
}
