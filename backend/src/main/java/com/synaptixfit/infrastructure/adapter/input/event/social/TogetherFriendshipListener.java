package com.synaptixfit.infrastructure.adapter.input.event.social;

import com.synaptixfit.application.port.input.together.LeaveSharedWithUserUseCase;
import com.synaptixfit.domain.event.social.FriendshipEnded;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Al bloquear o dejar de ser amigos ({@link FriendshipEnded}) deja lo compartido entre las dos personas: rachas,
 * retos y entrenos con amigos (ADR 0044). El caso de uso es idempotente.
 */
@Component
public class TogetherFriendshipListener {

    private final LeaveSharedWithUserUseCase leaveShared;

    public TogetherFriendshipListener(LeaveSharedWithUserUseCase leaveShared) {
        this.leaveShared = leaveShared;
    }

    @EventListener
    public void on(FriendshipEnded event) {
        leaveShared.leaveShared(event.userId(), event.otherUserId(), event.blocked());
    }
}
