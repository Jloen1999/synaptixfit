package com.synaptixfit.domain.port.output.auth;

import com.synaptixfit.domain.model.auth.PasswordResetToken;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/** Persistencia de los enlaces para restablecer la contraseña (solo la huella del token). */
public interface PasswordResetTokenRepositoryPort {

    PasswordResetToken save(PasswordResetToken token);

    Optional<PasswordResetToken> findByHash(String tokenHash);

    /** Enlaces pedidos por el usuario desde {@code since} (para el límite por hora). */
    int countCreatedSince(UUID userId, Instant since);

    /** Marca como usados los enlaces aún válidos del usuario: solo funciona el último. */
    void invalidateAllForUser(UUID userId, Instant when);
}
