package com.synaptixfit.domain.exception.auth;

import com.synaptixfit.domain.exception.InvalidInputException;

/** El enlace para restablecer la contraseña no existe, ya se usó o caducó (no se distingue cuál). */
public class PasswordResetTokenInvalidException extends InvalidInputException {

    public PasswordResetTokenInvalidException() {
        super("AUTH_RESET_TOKEN_INVALID", "Password reset link is invalid, used or expired");
    }
}
