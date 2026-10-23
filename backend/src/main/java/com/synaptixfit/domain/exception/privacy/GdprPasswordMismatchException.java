package com.synaptixfit.domain.exception.privacy;

import com.synaptixfit.domain.exception.ForbiddenOperationException;

/**
 * La contraseña de confirmación de la baja no es correcta. Es 403 y no 401 para que el cliente
 * no lo confunda con una sesión caducada.
 */
public class GdprPasswordMismatchException extends ForbiddenOperationException {

    public GdprPasswordMismatchException() {
        super("GDPR_PASSWORD_MISMATCH", "the confirmation password is not correct");
    }
}
