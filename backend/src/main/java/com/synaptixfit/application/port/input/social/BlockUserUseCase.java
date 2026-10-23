package com.synaptixfit.application.port.input.social;

import com.synaptixfit.domain.model.social.FriendshipView;
import java.util.UUID;

/** Bloquea a un usuario (con o sin relación previa). */
public interface BlockUserUseCase {

    FriendshipView block(UUID userId, UUID targetUserId);
}
