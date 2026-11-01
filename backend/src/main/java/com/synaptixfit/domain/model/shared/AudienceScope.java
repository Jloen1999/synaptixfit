package com.synaptixfit.domain.model.shared;

/**
 * Parte del contenido compartido de otros que se pide: todo lo visible, solo lo que llega por ser
 * amigo del autor o solo lo que cualquiera puede ver. Lo interpreta {@link EffectiveVisibility}.
 */
public enum AudienceScope {
    ALL,
    FRIENDS,
    PUBLIC
}
