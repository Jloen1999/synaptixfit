package com.synaptixfit.application.port.input.together;

import java.util.UUID;

/** Al bloquear o dejar de ser amigos, deja lo compartido entre las dos personas (ADR 0044). */
public interface LeaveSharedWithUserUseCase {

    void leaveShared(UUID userId, UUID otherUserId, boolean blocked);
}
