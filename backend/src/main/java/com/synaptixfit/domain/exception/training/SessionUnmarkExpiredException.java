package com.synaptixfit.domain.exception.training;

import com.synaptixfit.domain.exception.BusinessRuleException;

/**
 * Solo se desmarca una sesión el mismo día en que se terminó; las de días anteriores se corrigen o
 * se eliminan (desmarcarlas la dejaría abierta y abandonada).
 */
public class SessionUnmarkExpiredException extends BusinessRuleException {

    public SessionUnmarkExpiredException() {
        super("SESSION_UNMARK_EXPIRED", "Only sessions finished today can be unmarked; correct or delete it instead");
    }
}
