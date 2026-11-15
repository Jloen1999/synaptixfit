package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Dice que no a una racha propuesta. */
public interface DeclineFriendStreakUseCase {

    void decline(UUID userId, UUID streakId);
}
