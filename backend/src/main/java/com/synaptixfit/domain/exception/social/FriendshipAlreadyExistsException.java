package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ConflictException;
import java.util.UUID;

/** Ya existe una amistad aceptada o una solicitud pendiente enviada a ese usuario. */
public class FriendshipAlreadyExistsException extends ConflictException {

    public FriendshipAlreadyExistsException(UUID otherUserId) {
        super("FRIENDSHIP_ALREADY_EXISTS", "A friendship or pending request already exists with user " + otherUserId);
    }
}
