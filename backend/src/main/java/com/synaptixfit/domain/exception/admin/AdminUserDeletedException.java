package com.synaptixfit.domain.exception.admin;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** La cuenta está anonimizada o desactivada: solo admite exportar o eliminar definitivamente. */
public class AdminUserDeletedException extends BusinessRuleException {

    public AdminUserDeletedException() {
        super("ADMIN_USER_DELETED", "the account is deleted or anonymized");
    }
}
