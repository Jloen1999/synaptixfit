package com.synaptixfit.infrastructure.adapter.output.security;

import com.synaptixfit.domain.model.auth.Password;
import com.synaptixfit.domain.port.output.auth.PasswordHasherPort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/** Hash BCrypt (compatible con los hashes exportados de Supabase Auth). */
@Component
public class BCryptPasswordHasherAdapter implements PasswordHasherPort {

    private final PasswordEncoder encoder;

    public BCryptPasswordHasherAdapter(PasswordEncoder encoder) {
        this.encoder = encoder;
    }

    @Override
    public String hash(Password password) {
        return encoder.encode(password.value());
    }

    @Override
    public boolean matches(String rawPassword, String hash) {
        return rawPassword != null && hash != null && encoder.matches(rawPassword, hash);
    }
}
