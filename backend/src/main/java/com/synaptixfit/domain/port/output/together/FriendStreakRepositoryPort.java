package com.synaptixfit.domain.port.output.together;

import com.synaptixfit.domain.model.together.FriendStreak;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Rachas con un amigo (tabla {@code rachas_amigo}, ADR 0044). */
public interface FriendStreakRepositoryPort {

    Optional<FriendStreak> findById(UUID id);

    /** La racha entre dos personas, en cualquier sentido. */
    Optional<FriendStreak> findBetween(UUID userA, UUID userB);

    /** Rachas (propuestas o activas) en las que está la persona. */
    List<FriendStreak> findByUser(UUID userId);

    FriendStreak save(FriendStreak streak);

    void delete(UUID id);
}
