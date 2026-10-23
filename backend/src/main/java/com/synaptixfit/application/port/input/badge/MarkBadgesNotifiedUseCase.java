package com.synaptixfit.application.port.input.badge;

import java.util.List;
import java.util.UUID;

/** Marca insignias obtenidas como ya notificadas. */
public interface MarkBadgesNotifiedUseCase {

    void markBadgesNotified(UUID userId, List<UUID> badgeIds);
}
