package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Termina una racha con un amigo (o retira la propuesta). */
public interface EndFriendStreakUseCase {

    void end(UUID userId, UUID streakId);
}
