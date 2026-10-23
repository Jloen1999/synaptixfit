package com.synaptixfit.domain.exception.admin;

import com.synaptixfit.domain.exception.BusinessRuleException;

/**
 * Un administrador no puede aplicarse desde el panel acciones que le quitarían el acceso o la
 * cuenta (cambiar su rol, ocultarse, borrar sus datos, anonimizarse o eliminarse).
 */
public class AdminCannotTargetSelfException extends BusinessRuleException {

    public AdminCannotTargetSelfException() {
        super("ADMIN_CANNOT_TARGET_SELF", "administrators cannot apply this action to their own account");
    }
}
