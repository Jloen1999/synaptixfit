package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.ForbiddenOperationException;

/** La cuenta está eliminada o desactivada. */
public class AccountDisabledException extends ForbiddenOperationException {

    public AccountDisabledException() {
        super("AUTH_ACCOUNT_DISABLED", "Account is disabled");
    }
}
