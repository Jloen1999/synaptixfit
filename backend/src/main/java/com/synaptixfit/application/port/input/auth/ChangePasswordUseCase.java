package com.synaptixfit.application.port.input.auth;

/** Cambia la contraseña y revoca las demás sesiones. */
public interface ChangePasswordUseCase {

    record Command(java.util.UUID userId, String currentPassword, String newPassword) {}

    void changePassword(Command command);
}
