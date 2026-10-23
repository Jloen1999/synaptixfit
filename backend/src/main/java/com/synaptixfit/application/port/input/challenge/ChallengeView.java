package com.synaptixfit.application.port.input.challenge;

import com.synaptixfit.domain.model.challenge.Challenge;

/**
 * Reto visto por un usuario.
 *
 * @param ownerName nombre del autor cuando el reto es de otro usuario; {@code null} si es propio
 */
public record ChallengeView(Challenge challenge, boolean owned, String ownerName) {
}
