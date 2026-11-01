package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** La entrega o el examen vinculado vence fuera del periodo del reto: nunca podría completarlo a tiempo (ADR 0028). */
public class ChallengeLinkOutsidePeriodException extends BusinessRuleException {

    public ChallengeLinkOutsidePeriodException(UUID id) {
        super("CHALLENGE_LINK_OUTSIDE_PERIOD", "linked deadline " + id + " is due outside the challenge period");
    }
}
