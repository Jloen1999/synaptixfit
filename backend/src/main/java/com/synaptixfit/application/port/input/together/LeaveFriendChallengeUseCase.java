package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Sale de un reto con amigos en un toque (se puede volver con «Deshacer»). */
public interface LeaveFriendChallengeUseCase {

    void leave(UUID userId, UUID challengeId);
}
