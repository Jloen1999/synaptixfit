package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Propone una racha a un amigo mutuo. */
public interface ProposeFriendStreakUseCase {

    FriendStreakView propose(UUID userId, UUID friendId);
}
