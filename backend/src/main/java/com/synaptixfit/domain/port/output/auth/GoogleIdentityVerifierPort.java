package com.synaptixfit.domain.port.output.auth;

import com.synaptixfit.domain.model.auth.GoogleIdentity;

/** Verifica un ID token de Google y devuelve la identidad. Lanza InvalidGoogleTokenException si no es válido. */
public interface GoogleIdentityVerifierPort {

    GoogleIdentity verify(String idToken);
}
