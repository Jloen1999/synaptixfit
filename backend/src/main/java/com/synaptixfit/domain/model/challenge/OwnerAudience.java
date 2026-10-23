package com.synaptixfit.domain.model.challenge;

/**
 * Datos del autor de un reto vistos por otro usuario, para decidir con
 * {@link Challenge#isVisibleTo(OwnerAudience)} si puede verlo. Los lee {@code ChallengeAudiencePort}.
 *
 * @param ownerActive      la cuenta del autor no está eliminada
 * @param ownerShadowbanned el autor está silenciado (shadowban)
 * @param friends          hay una amistad aceptada entre ambos
 */
public record OwnerAudience(boolean ownerActive, boolean ownerShadowbanned, boolean friends) {
}
