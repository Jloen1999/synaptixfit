package com.synaptixfit.domain.exception.together;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** Esa plantilla no vale para un reto con amigos: sale de datos de bienestar, que nunca se comparten. */
public class FriendChallengeTemplateNotAllowedException extends BusinessRuleException {

    public FriendChallengeTemplateNotAllowedException(UUID templateId) {
        super("FRIEND_CHALLENGE_TEMPLATE_NOT_ALLOWED", "Template " + templateId + " cannot be shared");
    }
}
