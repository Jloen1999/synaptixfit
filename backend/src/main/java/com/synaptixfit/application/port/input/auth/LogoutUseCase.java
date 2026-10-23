package com.synaptixfit.application.port.input.auth;

/** Cierra la sesión revocando el token de refresco. */
public interface LogoutUseCase {

    void logout(String refreshToken);
}
