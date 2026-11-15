package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.NotFoundException;
import java.util.UUID;

/** La racha con un amigo no existe o no es de esta persona. */
public class FriendStreakNotFoundException extends NotFoundException {

    public FriendStreakNotFoundException(UUID id) {
        super("FRIEND_STREAK_NOT_FOUND", "Friend streak " + id + " not found");
    }
}
