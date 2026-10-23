package com.synaptixfit.application.port.input.social;

import java.util.UUID;

/** Elimina una relación: cancelar solicitud, eliminar amigo o desbloquear. */
public interface RemoveFriendshipUseCase {

    void remove(UUID userId, UUID friendshipId);
}
