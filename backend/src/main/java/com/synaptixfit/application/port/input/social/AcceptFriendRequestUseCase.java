package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.FriendshipView;
import java.util.UUID;

/** Acepta una solicitud de amistad recibida. */
public interface AcceptFriendRequestUseCase {

    FriendshipView accept(UUID userId, UUID friendshipId);
}
