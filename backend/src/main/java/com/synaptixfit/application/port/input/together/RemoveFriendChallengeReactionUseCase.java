package com.synaptixfit.application.port.input.together;

import java.time.LocalDate;
import java.util.UUID;

/** Quita mi reacción a una entrada del tablón de un reto con amigos. */
public interface RemoveFriendChallengeReactionUseCase {

    void removeReaction(UUID userId, UUID challengeId, UUID recipientId, LocalDate day);
}
