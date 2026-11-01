package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.shared.AuthorAudience;
import com.synaptixfit.domain.model.shared.EffectiveVisibility;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/**
 * Reglas de visibilidad del contenido social (sustituyen a las políticas RLS y a las funciones
 * {@code son_amigos}, {@code nivel_privacidad_de} y {@code excluir_si_shadowban}).
 *
 * <p>El perfil y el muro siguen la misma regla que el contenido compartido
 * ({@link EffectiveVisibility}), tomando el perfil como un contenido público. La consulta paginada del
 * muro aplica las mismas reglas en SQL; cualquier cambio aquí debe reflejarse en ella.
 */
public final class ContentVisibility {

    private ContentVisibility() {
    }

    /**
     * ¿Puede {@code viewerId} ver el contenido de {@code author}?
     * <ul>
     *   <li>El autor siempre ve lo suyo.</li>
     *   <li>Nadie más ve a autores eliminados o con shadowban, ni hay visibilidad si hay un bloqueo entre ambos.</li>
     *   <li>Autor PUBLIC: todos. FRIENDS: solo amigos con amistad aceptada. PRIVATE: nadie más.</li>
     * </ul>
     *
     * @param relation relación entre ambos o {@code null} si no hay ninguna
     */
    public static boolean canView(UUID viewerId, User author, Friendship relation) {
        if (author.id().equals(viewerId)) {
            return true;
        }
        return EffectiveVisibility.canView(Visibility.PUBLIC, audienceOf(author, relation));
    }

    /** Datos del autor vistos por otro usuario, con la relación entre ambos ({@code null} si no hay). */
    public static AuthorAudience audienceOf(User author, Friendship relation) {
        return new AuthorAudience(author.isActive(), author.shadowbanned(), author.privacy(),
                relation != null && relation.isAccepted(), relation != null && relation.isBlocked());
    }

    /**
     * ¿Existe {@code target} para {@code viewerId}? (perfil, solicitudes). Los usuarios eliminados,
     * con shadowban o que han bloqueado a quien mira se tratan como inexistentes.
     */
    public static boolean canDiscover(UUID viewerId, User target, Friendship relation) {
        if (target.id().equals(viewerId)) {
            return true;
        }
        if (!target.isActive() || target.shadowbanned()) {
            return false;
        }
        return relation == null || !relation.isBlocked() || relation.isBlockedBy(viewerId);
    }
}
