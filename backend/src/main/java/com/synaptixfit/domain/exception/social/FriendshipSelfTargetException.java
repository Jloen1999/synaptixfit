package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** Un usuario no puede enviarse solicitudes ni bloquearse a sí mismo. */
public class FriendshipSelfTargetException extends BusinessRuleException {

    public FriendshipSelfTargetException(UUID userId) {
        super("FRIENDSHIP_SELF_TARGET", "User " + userId + " cannot target themselves");
    }
}
