package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.NotFoundException;
import java.util.UUID;

/** El reto con amigos no existe o la persona no está (ni ha estado) invitada a él. */
public class FriendChallengeNotFoundException extends NotFoundException {

    public FriendChallengeNotFoundException(UUID id) {
        super("FRIEND_CHALLENGE_NOT_FOUND", "Friend challenge " + id + " not found");
    }
}
