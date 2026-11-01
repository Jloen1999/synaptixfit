package com.synaptixfit.domain.model.challenge;

/**
 * Estado visible de un reto: completado, por empezar (su inicio aún no ha llegado), activo (en plazo)
 * o vencido sin completar. La regla está en {@link Challenge#statusOf} (ADR 0028).
 */
public enum ChallengeStatus {
    UPCOMING,
    ACTIVE,
    COMPLETED,
    EXPIRED
}
