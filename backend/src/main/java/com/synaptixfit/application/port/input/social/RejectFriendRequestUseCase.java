package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.FriendshipView;
import java.util.UUID;

/** Rechaza una solicitud de amistad recibida. */
public interface RejectFriendRequestUseCase {

    FriendshipView reject(UUID userId, UUID friendshipId);
}
