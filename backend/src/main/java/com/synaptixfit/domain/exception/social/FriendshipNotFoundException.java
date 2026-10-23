package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La relación de amistad no existe o no pertenece al usuario. */
public class FriendshipNotFoundException extends ResourceNotFoundException {

    public FriendshipNotFoundException(UUID id) {
        super("FRIENDSHIP_NOT_FOUND", "Friendship", id);
    }
}
