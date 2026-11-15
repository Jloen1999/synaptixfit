package com.synaptixfit.domain.port.output.together;

import com.synaptixfit.domain.model.together.FriendChallenge;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Retos con amigos y sus personas (tablas {@code retos_amigos} y {@code retos_amigos_miembros}, ADR 0044). */
public interface FriendChallengeRepositoryPort {

    Optional<FriendChallenge> findById(UUID id);

    FriendChallenge save(FriendChallenge challenge);

    /** Retos en los que {@code userId} está invitado o dentro y que terminaron después de {@code endedAfter}. */
    List<FriendChallenge> findVisibleTo(UUID userId, Instant endedAfter);
}
