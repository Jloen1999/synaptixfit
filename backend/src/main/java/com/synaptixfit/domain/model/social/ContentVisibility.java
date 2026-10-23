package com.synaptixfit.domain.model.social;

import com.synaptixfit.domain.model.user.User;
import java.util.UUID;

/**
 * Reglas de visibilidad del contenido social (sustituyen a las políticas RLS y a las funciones
 * {@code son_amigos}, {@code nivel_privacidad_de} y {@code excluir_si_shadowban}).
 *
 * <p>La consulta paginada del muro aplica las mismas reglas en SQL; cualquier cambio aquí debe
 * reflejarse en ella.
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
        if (!author.isActive() || author.shadowbanned() || (relation != null && relation.isBlocked())) {
            return false;
        }
        return switch (author.privacy()) {
            case PUBLIC -> true;
            case FRIENDS -> relation != null && relation.isAccepted();
            case PRIVATE -> false;
        };
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
