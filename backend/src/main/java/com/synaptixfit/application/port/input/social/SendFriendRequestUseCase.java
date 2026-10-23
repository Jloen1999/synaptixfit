package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.FriendshipView;
import java.util.UUID;

/** Envía una solicitud de amistad (si el otro ya había pedido, se acepta directamente). */
public interface SendFriendRequestUseCase {

    FriendshipView sendRequest(UUID requesterId, UUID addresseeId);
}
