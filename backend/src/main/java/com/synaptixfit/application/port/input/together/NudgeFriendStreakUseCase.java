package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** «Recordárselo»: aviso suave al amigo al que le falta su parte de hoy, como mucho uno al día. */
public interface NudgeFriendStreakUseCase {

    FriendStreakView nudge(UUID userId, UUID streakId);
}
