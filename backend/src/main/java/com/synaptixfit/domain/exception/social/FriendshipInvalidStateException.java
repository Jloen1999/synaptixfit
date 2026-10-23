package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** La transición pedida no es válida en el estado actual de la relación (p. ej. aceptar algo que no es una solicitud recibida pendiente). */
public class FriendshipInvalidStateException extends BusinessRuleException {

    public FriendshipInvalidStateException(UUID id) {
        super("FRIENDSHIP_INVALID_STATE", "Friendship " + id + " does not allow this transition");
    }
}
