package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** El usuario no existe, está eliminado o no es visible para quien pregunta (shadowban o bloqueo). */
public class SocialUserNotFoundException extends ResourceNotFoundException {

    public SocialUserNotFoundException(UUID id) {
        super("SOCIAL_USER_NOT_FOUND", "User", id);
    }
}
