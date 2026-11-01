package com.synaptixfit.domain.model.shared;

/**
 * Datos del autor de un contenido vistos por otro usuario, para decidir con
 * {@link EffectiveVisibility#canView} si puede verlo. Los leen los adaptadores de cada módulo.
 *
 * @param authorActive       la cuenta del autor no está eliminada
 * @param authorShadowbanned el autor está silenciado (shadowban)
 * @param authorPrivacy      privacidad del perfil del autor
 * @param friends            hay una amistad aceptada entre ambos
 * @param blocked            uno de los dos ha bloqueado al otro
 */
public record AuthorAudience(boolean authorActive, boolean authorShadowbanned, Visibility authorPrivacy,
                             boolean friends, boolean blocked) {

    /** Autor inexistente: nadie ve su contenido. */
    public static AuthorAudience missing() {
        return new AuthorAudience(false, false, Visibility.PRIVATE, false, false);
    }
}
