package com.synaptixfit.domain.port.output.auth;

import java.time.Instant;

/**
 * Envía el correo con el enlace para restablecer la contraseña. El adaptador compone el texto (en el idioma de
 * la petición) y el enlace a la app. No lleva el nombre del usuario: lo escribe quien se registra (sin verificar
 * el correo) y serviría para colar texto engañoso en un correo de nuestro dominio. Nunca falla hacia fuera: un
 * error de envío se registra y no revela si la cuenta existe.
 */
public interface PasswordResetMailerPort {

    void sendPasswordReset(String email, String rawToken, Instant expiresAt);
}
