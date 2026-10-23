package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** El ámbito del reto (académico o físico) no está entre los que usa la persona (su enfoque). */
public class ChallengeTypeOutsideFocusException extends BusinessRuleException {

    public ChallengeTypeOutsideFocusException() {
        super("CHALLENGE_TYPE_OUTSIDE_FOCUS", "challenge type is outside the user's usage focus");
    }
}
