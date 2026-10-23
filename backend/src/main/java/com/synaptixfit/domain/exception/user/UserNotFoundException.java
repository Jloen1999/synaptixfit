package com.synaptixfit.domain.exception.user;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El usuario no existe. */
public class UserNotFoundException extends ResourceNotFoundException {

    public UserNotFoundException(UUID id) {
        super("USER_NOT_FOUND", "User", id);
    }
}
