package com.synaptixfit.application.port.input.auth;

/** Renueva la sesión rotando el token de refresco. */
public interface RefreshSessionUseCase {

    AuthSession refresh(String refreshToken);
}
