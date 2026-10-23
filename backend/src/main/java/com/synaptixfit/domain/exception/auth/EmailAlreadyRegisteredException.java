package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.ConflictException;

/** Ya existe una cuenta con ese email. */
public class EmailAlreadyRegisteredException extends ConflictException {

    public EmailAlreadyRegisteredException() {
        super("AUTH_EMAIL_ALREADY_REGISTERED", "Email already registered");
    }
}
