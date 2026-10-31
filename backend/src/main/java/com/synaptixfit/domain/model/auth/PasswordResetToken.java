package com.synaptixfit.domain.model.auth;

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
 * Enlace para restablecer la contraseña que se envía por correo. Como los tokens de refresco, solo se guarda la
 * huella SHA-256: quien lea la BD no puede usar los enlaces. Sirve una vez y caduca a los 30 minutos (un tiempo
 * corto porque el correo puede quedar abierto en otros dispositivos).
 */
public final class PasswordResetToken {

    public static final Duration TTL = Duration.ofMinutes(30);
    /** Correos por usuario y hora: frena que alguien llene el buzón de otro pidiendo enlaces. */
    public static final int MAX_PER_HOUR = 3;

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int TOKEN_BYTES = 32;

    private final UUID id;
    private final UUID userId;
    private final String tokenHash;
    private final Instant createdAt;
    private final Instant expiresAt;
    private Instant usedAt;

    public PasswordResetToken(UUID id, UUID userId, String tokenHash, Instant createdAt, Instant expiresAt,
                              Instant usedAt) {
        this.id = Guard.notNull(id, "id");
        this.userId = Guard.notNull(userId, "userId");
        this.tokenHash = Guard.notNull(tokenHash, "tokenHash");
        this.createdAt = Guard.notNull(createdAt, "createdAt");
        this.expiresAt = Guard.notNull(expiresAt, "expiresAt");
        this.usedAt = usedAt;
    }

    /** Enlace nuevo con el token en claro, que solo existe para enviarlo por correo. */
    public record Issued(PasswordResetToken token, String rawToken) {
    }

    public static Issued issue(UUID userId, Instant now) {
        byte[] bytes = new byte[TOKEN_BYTES];
        RANDOM.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        return new Issued(new PasswordResetToken(UUID.randomUUID(), userId, hash(raw), now, now.plus(TTL), null), raw);
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

    public boolean isUsableAt(Instant now) {
        return usedAt == null && now.isBefore(expiresAt);
    }

    public void markUsed(Instant now) {
        if (usedAt == null) {
            usedAt = now;
        }
    }

    public UUID id() { return id; }
    public UUID userId() { return userId; }
    public String tokenHash() { return tokenHash; }
    public Instant createdAt() { return createdAt; }
    public Instant expiresAt() { return expiresAt; }
    public Instant usedAt() { return usedAt; }
}
