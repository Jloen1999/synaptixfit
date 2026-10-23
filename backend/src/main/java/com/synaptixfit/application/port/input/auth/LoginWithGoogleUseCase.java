package com.synaptixfit.application.port.input.auth;

/** Inicia sesión (o registra) con un ID token de Google. */
public interface LoginWithGoogleUseCase {

    AuthSession loginWithGoogle(String idToken);
}
