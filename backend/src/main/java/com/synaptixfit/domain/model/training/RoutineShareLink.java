package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.Guard;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Enlace para copiar una rutina (ADR 0043). Lleva un token aleatorio de 256 bits, sin datos de nadie: quien lo tiene
 * y ha iniciado sesión ve la rutina y puede copiarla. Solo se guarda la huella SHA-256 del token (como el calendario
 * suscrito, ADR 0020); el token en claro se entrega una vez al crearlo. Caduca a los {@value #VALID_DAYS} días y el
 * dueño lo revoca cuando quiera. Cada rutina admite como mucho {@value #MAX_ACTIVE_PER_ROUTINE} enlaces vigentes a la
 * vez, para que no se fabriquen sin fin.
 */
public record RoutineShareLink(UUID id, UUID routineId, UUID ownerId, String tokenHash, Instant createdAt,
                               Instant expiresAt, Instant revokedAt) {

    public static final int VALID_DAYS = 30;
    public static final int MAX_ACTIVE_PER_ROUTINE = 5;
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int TOKEN_BYTES = 32;

    public RoutineShareLink {
        Guard.notNull(id, "id");
        Guard.notNull(routineId, "routineId");
        Guard.notNull(ownerId, "ownerId");
        Guard.notNull(tokenHash, "tokenHash");
        Guard.notNull(createdAt, "createdAt");
        Guard.notNull(expiresAt, "expiresAt");
    }

    /** Enlace nuevo con el token en claro, que solo existe en este momento. */
    public record Issued(RoutineShareLink link, String token) {
    }

    public static Issued issue(UUID routineId, UUID ownerId, Instant now) {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        RoutineShareLink link = new RoutineShareLink(UUID.randomUUID(), routineId, ownerId, hash(token), now,
                now.plus(Duration.ofDays(VALID_DAYS)), null);
        return new Issued(link, token);
    }

    /** Vale ahora: no está revocado ni ha caducado. */
    public boolean isActiveAt(Instant now) {
        return revokedAt == null && now.isBefore(expiresAt);
    }

    /**
     * ¿Lo puede abrir {@code viewerId}? Tiene que estar vigente y, si no es el dueño, el dueño sigue activo, no está
     * silenciado y ninguno de los dos ha bloqueado al otro: un enlace no se salta un bloqueo ni la moderación.
     */
    public boolean opensFor(UUID viewerId, AuthorAudience owner, Instant now) {
        if (!isActiveAt(now)) {
            return false;
        }
        return ownerId.equals(viewerId)
                || (owner.authorActive() && !owner.authorShadowbanned() && !owner.blocked());
    }

    /** Huella del token tal como se guarda y se busca. */
    public static String hash(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is always available in the JDK", e);
        }
    }
}
