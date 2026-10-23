package com.synaptixfit.application.port.input.auth;

/** Inicia sesión con email y contraseña. */
public interface LoginUseCase {

    record Command(String email, String password) {}

    AuthSession login(Command command);
}
