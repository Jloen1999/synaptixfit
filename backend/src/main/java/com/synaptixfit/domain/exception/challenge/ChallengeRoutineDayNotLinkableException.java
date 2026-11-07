package com.synaptixfit.domain.exception.challenge;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/**
 * El día de rutina elegido para una tarea de reto no se puede vincular: no es de la rutina en curso, no tiene
 * ejercicios o ya está hecho o saltado, así que nunca completaría la tarea (ADR 0032, {@code RoutineDayTarget}).
 */
public class ChallengeRoutineDayNotLinkableException extends BusinessRuleException {

    public ChallengeRoutineDayNotLinkableException(UUID dayId) {
        super("CHALLENGE_ROUTINE_DAY_NOT_LINKABLE", "routine day " + dayId + " cannot be linked to a challenge task");
    }
}
