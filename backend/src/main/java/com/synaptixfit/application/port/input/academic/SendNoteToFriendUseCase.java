package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/**
 * «Compartir › Con un amigo» (ADR 0064): deja leer un apunte propio a un amigo mutuo y le avisa. Repetirlo no
 * duplica el permiso.
 */
public interface SendNoteToFriendUseCase {

    /** A quién se ha pasado: su id y su nombre, para el aviso «Enviado a Ana». */
    record SentNote(UUID friendId, String friendName) {
    }

    SentNote sendToFriend(UUID userId, UUID noteId, UUID friendId);
}
