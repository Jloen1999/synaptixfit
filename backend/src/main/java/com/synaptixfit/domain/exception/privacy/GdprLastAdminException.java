package com.synaptixfit.domain.exception.privacy;

import com.synaptixfit.domain.exception.BusinessRuleException;

/** El último administrador activo no puede darse de baja: la plataforma quedaría sin gestión. */
public class GdprLastAdminException extends BusinessRuleException {

    public GdprLastAdminException() {
        super("GDPR_LAST_ADMIN", "the last active administrator cannot delete their account");
    }
}
