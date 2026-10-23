package com.synaptixfit.domain.port.output.auth;

import com.synaptixfit.domain.model.auth.RefreshToken;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de tokens de refresco. */
public interface RefreshTokenRepositoryPort {

    RefreshToken save(RefreshToken token);

    Optional<RefreshToken> findByHash(String tokenHash);

    void revokeAllForUser(UUID userId, Instant when);
}
