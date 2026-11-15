package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Acepta una racha propuesta: cuenta desde hoy. */
public interface AcceptFriendStreakUseCase {

    FriendStreakView accept(UUID userId, UUID streakId);
}
