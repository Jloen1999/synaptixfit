package com.synaptixfit.domain.exception.social;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** El usuario ha bloqueado a la otra persona: debe desbloquearla antes de enviarle una solicitud. */
public class FriendshipBlockedException extends BusinessRuleException {

    public FriendshipBlockedException(UUID otherUserId) {
        super("FRIENDSHIP_BLOCKED", "You have blocked user " + otherUserId);
    }
}
