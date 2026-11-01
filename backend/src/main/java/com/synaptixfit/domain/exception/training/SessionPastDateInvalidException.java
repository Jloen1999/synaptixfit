package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** Una sesión pasada solo se registra con fecha de hoy o de los 7 días anteriores. */
public class SessionPastDateInvalidException extends BusinessRuleException {

    public SessionPastDateInvalidException() {
        super("SESSION_PAST_DATE_INVALID", "Past sessions must be dated today or within the previous 7 days");
    }
}
