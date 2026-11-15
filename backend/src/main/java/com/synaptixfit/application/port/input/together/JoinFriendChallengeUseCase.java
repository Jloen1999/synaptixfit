package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Acepta la invitación a un reto con amigos (o vuelve tras salir, mientras siga en marcha). */
public interface JoinFriendChallengeUseCase {

    FriendChallengeView join(UUID userId, UUID challengeId, String language);
}
