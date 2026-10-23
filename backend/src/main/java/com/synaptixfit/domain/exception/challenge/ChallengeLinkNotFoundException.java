package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.ResourceNotFoundException;
import java.util.UUID;

/** La entrega, examen o bloque vinculado no existe o no es del usuario. */
public class ChallengeLinkNotFoundException extends ResourceNotFoundException {

    public ChallengeLinkNotFoundException(UUID id) {
        super("CHALLENGE_LINK_NOT_FOUND", "Linked entity", id);
    }
}
