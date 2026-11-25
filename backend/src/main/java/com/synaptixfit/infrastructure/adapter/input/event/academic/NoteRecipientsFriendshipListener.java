package com.synaptixfit.infrastructure.adapter.input.event.academic;

import com.synaptixfit.application.port.input.academic.RevokeNoteRecipientsUseCase;
import com.synaptixfit.domain.event.social.FriendshipEnded;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Al bloquear o dejar de ser amigos ({@link FriendshipEnded}) quita los apuntes que se habían pasado entre los dos
 * con «Compartir › Con un amigo» (ADR 0064). Idempotente.
 */
@Component
public class NoteRecipientsFriendshipListener {

    private final RevokeNoteRecipientsUseCase revoke;

    public NoteRecipientsFriendshipListener(RevokeNoteRecipientsUseCase revoke) {
        this.revoke = revoke;
    }

    @EventListener
    public void on(FriendshipEnded event) {
        revoke.revokeBetween(event.userId(), event.otherUserId());
    }
}
