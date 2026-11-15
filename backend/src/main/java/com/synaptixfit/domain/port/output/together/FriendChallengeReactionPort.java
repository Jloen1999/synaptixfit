package com.synaptixfit.domain.port.output.together;

import com.synaptixfit.domain.model.together.ReactionRecord;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Reacciones fijas del tablón de los retos con amigos (tabla {@code reacciones_reto_amigos}, ADR 0044). */
public interface FriendChallengeReactionPort {

    /** Guarda o cambia la reacción de su autor a esa entrada. */
    void put(ReactionRecord reaction);

    void remove(UUID challengeId, UUID recipientId, LocalDate day, UUID authorId);

    List<ReactionRecord> findByChallenge(UUID challengeId);
}
