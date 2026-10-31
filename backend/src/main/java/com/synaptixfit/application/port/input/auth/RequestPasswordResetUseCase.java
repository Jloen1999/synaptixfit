package com.synaptixfit.application.port.input.auth;

/**
 * Envía por correo un enlace para restablecer la contraseña. Responde igual exista o no la cuenta (no revela qué
 * correos están registrados) y no envía más de {@code PasswordResetToken.MAX_PER_HOUR} por hora.
 */
public interface RequestPasswordResetUseCase {

    void requestPasswordReset(String email);
}
