package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.Reaction;
import java.time.LocalDate;
import java.util.UUID;

/** Pone o cambia una reacción fija a lo que sumó alguien un día en un reto con amigos. */
public interface ReactFriendChallengeUseCase {

    void react(UUID userId, UUID challengeId, UUID recipientId, LocalDate day, Reaction reaction);
}
