package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Detalle de un reto con amigos con su tablón. */
public interface GetFriendChallengeUseCase {

    FriendChallengeView get(UUID userId, UUID challengeId, String language);
}
