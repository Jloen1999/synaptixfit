package com.synaptixfit.domain.exception.notification;

import com.synaptixfit.domain.exception.InvalidInputException;

/** Opciones de avisos fuera de las cerradas (antelación, días antes de una entrega, hora del resumen; ADR 0035). */
public class ReminderOptionsInvalidException extends InvalidInputException {

    public ReminderOptionsInvalidException(String message) {
        super("REMINDER_OPTIONS_INVALID", message);
    }
}
