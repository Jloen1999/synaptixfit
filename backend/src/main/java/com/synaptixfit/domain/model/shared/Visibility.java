package com.synaptixfit.domain.model.shared;

/**
 * Quién puede ver un contenido o perfil. Valor único para toda la aplicación.
 *
 * <p>El orden de declaración importa: va de más a menos restrictivo y {@link EffectiveVisibility}
 * lo usa para quedarse con el más restrictivo de dos valores.
 */
public enum Visibility {
    PRIVATE,
    FRIENDS,
    PUBLIC
}
