package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** Solo se invita a amigos mutuos (amistad aceptada y sin bloqueos). */
public class TogetherNotFriendsException extends BusinessRuleException {

    public TogetherNotFriendsException(UUID otherUserId) {
        super("TOGETHER_NOT_FRIENDS", "User " + otherUserId + " is not a friend");
    }
}
