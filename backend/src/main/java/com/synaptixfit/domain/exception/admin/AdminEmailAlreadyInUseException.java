package com.synaptixfit.domain.exception.admin;

import com.synaptixfit.domain.exception.ConflictException;

/** El email nuevo ya pertenece a otra cuenta. */
public class AdminEmailAlreadyInUseException extends ConflictException {

    public AdminEmailAlreadyInUseException() {
        super("ADMIN_EMAIL_ALREADY_IN_USE", "the email is already used by another account");
    }
}
