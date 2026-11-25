package com.synaptixfit.application.port.input.academic;

import com.synaptixfit.domain.model.shared.Visibility;
import java.util.UUID;

/**
 * «Compartir › En el muro» (ADR 0064): publica un apunte propio en el muro y lo abre a quien ve el muro (público,
 * con el tope del perfil). Publicarlo dos veces no duplica la publicación.
 */
public interface ShareNoteOnWallUseCase {

    /**
     * @param comment texto opcional de la publicación; sin él, el título del apunte
     */
    record Command(UUID userId, UUID noteId, String comment) {
    }

    /**
     * @param alreadyShared ya estaba en el muro (no se ha publicado otra vez)
     * @param visibility    visibilidad del apunte después de publicarlo
     */
    record WallShare(boolean alreadyShared, Visibility visibility) {
    }

    WallShare shareOnWall(Command command);
}
