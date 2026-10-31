package com.synaptixfit.application.port.input.auth;

/** Pone una contraseña nueva con el enlace del correo y cierra todas las sesiones abiertas. */
public interface ResetPasswordUseCase {

    record Command(String token, String newPassword) {
        @Override
        public String toString() {
            return "Command[***]";
        }
    }

    void resetPassword(Command command);
}
