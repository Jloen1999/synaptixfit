package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.ConflictException;
import java.util.UUID;

/** Ya hay una racha (propuesta o activa) con esa persona. */
public class FriendStreakAlreadyExistsException extends ConflictException {

    public FriendStreakAlreadyExistsException(UUID friendId) {
        super("FRIEND_STREAK_ALREADY_EXISTS", "Friend streak with " + friendId + " already exists");
    }
}
