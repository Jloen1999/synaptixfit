package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.FriendChallengeMode;
import java.util.Set;
import java.util.UUID;

/** Crea un reto con amigos mutuos desde una plantilla e invita a los amigos. */
public interface CreateFriendChallengeUseCase {

    FriendChallengeView create(Command command, String language);

    record Command(UUID userId, UUID templateId, int days, FriendChallengeMode mode, Set<UUID> friendIds) {
    }
}
