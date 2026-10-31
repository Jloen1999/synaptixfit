package com.synaptixfit.domain.model.planner;

import com.synaptixfit.domain.model.shared.Guard;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Suscripción al calendario de un usuario: un enlace privado con un token aleatorio de 256 bits que los
 * calendarios externos consultan sin iniciar sesión. Solo se guarda la huella SHA-256 del token; el token en
 * claro se entrega una vez al crearlo (como una contraseña) y crear otro invalida el anterior.
 */
public record CalendarFeed(UUID userId, String tokenHash, Instant createdAt) {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int TOKEN_BYTES = 32;

    public CalendarFeed {
        Guard.notNull(userId, "userId");
        Guard.notNull(tokenHash, "tokenHash");
        Guard.notNull(createdAt, "createdAt");
    }

    /** Suscripción nueva con el token en claro, que solo existe en este momento. */
    public record Issued(CalendarFeed feed, String token) {
    }

    public static Issued issue(UUID userId, Instant now) {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        return new Issued(new CalendarFeed(userId, hash(token), now), token);
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
