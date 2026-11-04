package com.synaptixfit.application.port.input.auth;

/** Registra una cuenta con email y contraseña. */
public interface RegisterUserUseCase {

    /**
     * @param acceptedLegalVersion versión de la política que la persona leyó y aceptó en el registro (ADR 0034);
     *                             nula en apps antiguas, que la pedirán al entrar
     */
    record Command(String email, String password, String fullName, String acceptedLegalVersion) {

        public Command(String email, String password, String fullName) {
            this(email, password, fullName, null);
        }
    }

    AuthSession register(Command command);
}
