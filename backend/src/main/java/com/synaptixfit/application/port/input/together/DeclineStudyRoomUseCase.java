package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Dice que no a la invitación a una sala (ADR 0045). */
public interface DeclineStudyRoomUseCase {

    void decline(UUID userId, UUID roomId);
}
