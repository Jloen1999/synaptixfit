package com.synaptixfit.domain.model.notification;

import com.synaptixfit.domain.model.shared.Guard;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

/**
 * Suscripción al resumen semanal por correo (ADR 0022). Doble confirmación: el registro no verifica el correo,
 * así que, salvo que Google ya lo haya verificado, empieza pendiente y solo se activa con el enlace que se manda a
 * ese buzón. Del token de confirmación solo se guarda la huella; el de baja se guarda tal cual porque va en cada
 * correo y solo sirve para darse de baja.
 */
public final class WeeklyEmailSubscription {

    public enum Status {
        PENDING,
        ACTIVE
    }

    private static final SecureRandom RANDOM = new SecureRandom();
    /**
     * Un correo de confirmación como mucho cada 10 minutos: el registro no verifica el correo, y sin este límite
     * se podría llenar el buzón de otra persona (y agotar el cupo diario de Resend) pulsando el interruptor.
     */
    public static final Duration CONFIRMATION_RESEND_AFTER = Duration.ofMinutes(10);
    /** El enlace de confirmación deja de servir a los 7 días. */
    public static final Duration CONFIRMATION_TTL = Duration.ofDays(7);

    private final UUID userId;
    private Status status;
    private String language;
    private String confirmTokenHash;
    private final String unsubscribeToken;
    private LocalDate lastSentWeek;
    private Instant updatedAt;

    public WeeklyEmailSubscription(UUID userId, Status status, String language, String confirmTokenHash,
                                   String unsubscribeToken, LocalDate lastSentWeek, Instant updatedAt) {
        this.userId = Guard.notNull(userId, "userId");
        this.status = Guard.notNull(status, "status");
        this.language = Guard.notNull(language, "language");
        this.confirmTokenHash = confirmTokenHash;
        this.unsubscribeToken = Guard.notNull(unsubscribeToken, "unsubscribeToken");
        this.lastSentWeek = lastSentWeek;
        this.updatedAt = Guard.notNull(updatedAt, "updatedAt");
    }

    /** Suscripción nueva; con {@code confirmToken} en claro si hay que confirmarla por correo. */
    public record Started(WeeklyEmailSubscription subscription, String confirmToken) {
    }

    /** @param verifiedEmail el correo ya está verificado (cuenta de Google): se activa sin confirmar */
    public static Started start(UUID userId, String language, boolean verifiedEmail, Instant now) {
        String unsubscribe = randomToken();
        if (verifiedEmail) {
            return new Started(new WeeklyEmailSubscription(userId, Status.ACTIVE, language, null, unsubscribe, null,
                    now), null);
        }
        String confirm = randomToken();
        return new Started(new WeeklyEmailSubscription(userId, Status.PENDING, language, hash(confirm), unsubscribe,
                null, now), confirm);
    }

    /** ¿Se puede mandar otro correo de confirmación? Solo pendiente y pasado el plazo desde el anterior. */
    public boolean canResendConfirmation(Instant now) {
        return status == Status.PENDING && !now.isBefore(updatedAt.plus(CONFIRMATION_RESEND_AFTER));
    }

    /** ¿Sirve aún el enlace de confirmación? */
    public boolean confirmationValidAt(Instant now) {
        return status == Status.PENDING && now.isBefore(updatedAt.plus(CONFIRMATION_TTL));
    }

    public void confirm(Instant now) {
        status = Status.ACTIVE;
        confirmTokenHash = null;
        updatedAt = now;
    }

    public void changeLanguage(String newLanguage, Instant now) {
        language = Guard.notNull(newLanguage, "language");
        updatedAt = now;
    }

    /** ¿Ya se envió el resumen de la semana que empieza en {@code monday}? (el envío se repite sin duplicar) */
    public boolean wasSentFor(LocalDate monday) {
        return monday.equals(lastSentWeek);
    }

    public void markSent(LocalDate monday, Instant now) {
        lastSentWeek = monday;
        updatedAt = now;
    }

    public boolean isActive() {
        return status == Status.ACTIVE;
    }

    /** Huella del token de confirmación tal como se guarda y se busca. */
    public static String hash(String token) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is always available in the JDK", e);
        }
    }

    private static String randomToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public UUID userId() { return userId; }
    public Status status() { return status; }
    public String language() { return language; }
    public String confirmTokenHash() { return confirmTokenHash; }
    public String unsubscribeToken() { return unsubscribeToken; }
    public LocalDate lastSentWeek() { return lastSentWeek; }
    public Instant updatedAt() { return updatedAt; }
}
