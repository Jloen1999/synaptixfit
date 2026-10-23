package com.synaptixfit.domain.port.output.auth;

import com.synaptixfit.domain.model.auth.Password;

/** Hash y verificación de contraseñas. */
public interface PasswordHasherPort {

    String hash(Password password);

    boolean matches(String rawPassword, String hash);
}
