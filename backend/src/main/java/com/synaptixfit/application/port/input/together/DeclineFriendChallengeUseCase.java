package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Dice que no a la invitación a un reto con amigos. */
public interface DeclineFriendChallengeUseCase {

    void decline(UUID userId, UUID challengeId);
}
