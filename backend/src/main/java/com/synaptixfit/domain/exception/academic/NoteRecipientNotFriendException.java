package com.synaptixfit.domain.exception.academic;

import com.synaptixfit.domain.exception.BusinessRuleException;
import java.util.UUID;

/** Un apunte solo se pasa a un amigo mutuo (amistad aceptada, sin bloqueo y con la cuenta activa) (ADR 0064). */
public class NoteRecipientNotFriendException extends BusinessRuleException {

    public NoteRecipientNotFriendException(UUID recipientId) {
        super("NOTE_RECIPIENT_NOT_FRIEND", "User " + recipientId + " is not a friend");
    }
}
