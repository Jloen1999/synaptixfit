package com.synaptixfit.domain.model.shared;

import java.util.Collections;
import java.util.EnumSet;
import java.util.Set;

/**
 * Regla única de visibilidad del contenido compartido (apuntes, rutinas, retos y, a través de
 * {@code ContentVisibility}, el perfil y el muro).
 *
 * <p>La visibilidad efectiva es la más restrictiva entre la del contenido y la del perfil del autor:
 * un apunte «público» de un perfil «solo amigos» solo lo ven sus amigos. Nadie ve contenido de
 * autores eliminados o silenciados, ni si hay un bloqueo en cualquier sentido. Lo propio lo decide
 * cada caso de uso (el autor siempre ve lo suyo).
 *
 * <p>Los conjuntos de niveles son cerrados hacia arriba (si contienen FRIENDS contienen PUBLIC), así
 * que «el mínimo de dos niveles está en el conjunto» equivale a «los dos están en el conjunto». Por eso
 * las consultas paginadas pueden filtrar con {@code visibilidad IN (...) AND nivel_privacidad IN (...)}
 * recibiendo estos niveles como parámetros, sin repetir la regla en SQL.
 */
public final class EffectiveVisibility {

    private static final Set<Visibility> SHARED = Collections.unmodifiableSet(
            EnumSet.of(Visibility.FRIENDS, Visibility.PUBLIC));
    private static final Set<Visibility> ANYONE = Collections.unmodifiableSet(EnumSet.of(Visibility.PUBLIC));

    private EffectiveVisibility() {
    }

    /**
     * La más restrictiva de las dos. {@link Visibility} está declarada de más a menos restrictiva;
     * un valor nulo cuenta como privado.
     */
    public static Visibility of(Visibility content, Visibility profile) {
        Visibility c = content == null ? Visibility.PRIVATE : content;
        Visibility p = profile == null ? Visibility.PRIVATE : profile;
        return c.compareTo(p) <= 0 ? c : p;
    }

    /** Niveles que alguien ve por ser amigo del autor en ese ámbito (vacío si el ámbito no los incluye). */
    public static Set<Visibility> levelsForFriends(AudienceScope scope) {
        return scope == AudienceScope.PUBLIC ? Set.of() : SHARED;
    }

    /** Niveles que ve cualquier usuario en ese ámbito (vacío si el ámbito exige amistad). */
    public static Set<Visibility> levelsForAnyone(AudienceScope scope) {
        return scope == AudienceScope.FRIENDS ? Set.of() : ANYONE;
    }

    /** Niveles con los que un contenido propio se considera compartido (lo que otros pueden llegar a ver). */
    public static Set<Visibility> sharedLevels() {
        return SHARED;
    }

    /** ¿Ve otro usuario un contenido con visibilidad {@code content} de ese autor, dentro del ámbito? */
    public static boolean canView(Visibility content, AuthorAudience author, AudienceScope scope) {
        if (!author.authorActive() || author.authorShadowbanned() || author.blocked()) {
            return false;
        }
        Visibility effective = of(content, author.authorPrivacy());
        return (author.friends() && levelsForFriends(scope).contains(effective))
                || levelsForAnyone(scope).contains(effective);
    }

    /** {@link #canView(Visibility, AuthorAudience, AudienceScope)} con todo lo visible. */
    public static boolean canView(Visibility content, AuthorAudience author) {
        return canView(content, author, AudienceScope.ALL);
    }
}
