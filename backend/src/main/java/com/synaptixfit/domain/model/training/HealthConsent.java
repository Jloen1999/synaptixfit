package com.synaptixfit.domain.model.training;

import com.synaptixfit.domain.model.shared.Guard;

import java.time.Instant;
import java.util.UUID;

/**
 * Consentimiento expreso para guardar el registro diario (sueño, energía, agujetas, dolor), que son datos de salud
 * (art. 9 RGPD, ADR 0034). Se da aparte de aceptar la política y se puede retirar; retirarlo deja de usar los
 * registros a partir de ese momento.
 *
 * <p>{@code textVersion}: versión del texto que se aceptó. Desde la versión {@value #BODY_WEIGHT_TEXT_VERSION} el
 * texto dice que también cubre el peso del perfil para proponer el peso de partida (ADR 0054); quien aceptó un texto
 * anterior no lo consintió para eso.
 */
public record HealthConsent(UUID userId, Instant givenAt, Instant withdrawnAt, int textVersion) {

    /** Versión del texto que enseña la app hoy. */
    public static final int CURRENT_TEXT_VERSION = 2;
    /** Primera versión del texto que incluye el peso corporal para el peso de partida. */
    public static final int BODY_WEIGHT_TEXT_VERSION = 2;

    public HealthConsent {
        Guard.notNull(userId, "userId");
        Guard.notNull(givenAt, "givenAt");
        Guard.range(textVersion, "textVersion", 1, 1000);
    }

    /** Consentimiento con el primer texto (antes de ADR 0054). */
    public HealthConsent(UUID userId, Instant givenAt, Instant withdrawnAt) {
        this(userId, givenAt, withdrawnAt, 1);
    }

    public static HealthConsent give(UUID userId, Instant now) {
        return new HealthConsent(userId, now, null, CURRENT_TEXT_VERSION);
    }

    public HealthConsent withdraw(Instant now) {
        return new HealthConsent(userId, givenAt, now, textVersion);
    }

    /** Dado y no retirado. */
    public boolean active() {
        return withdrawnAt == null;
    }

    /** Se aceptó el texto que se enseña hoy (si no, hay que volver a pedirlo para usos nuevos). */
    public boolean current() {
        return textVersion >= CURRENT_TEXT_VERSION;
    }

    /** Vigente y con un texto que cubre usar el peso del perfil para el peso de partida (ADR 0054). */
    public boolean coversBodyWeight() {
        return active() && textVersion >= BODY_WEIGHT_TEXT_VERSION;
    }
}
