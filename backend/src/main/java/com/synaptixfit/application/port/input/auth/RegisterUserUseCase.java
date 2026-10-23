package com.synaptixfit.application.port.input.auth;

/** Registra una cuenta con email y contraseña. */
public interface RegisterUserUseCase {

    record Command(String email, String password, String fullName) {}

    AuthSession register(Command command);
}
