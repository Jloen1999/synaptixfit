package com.synaptixfit.application.port.input.academic;

import java.util.UUID;

/**
 * Al dejar de ser amigos o bloquear, los apuntes que se pasaron entre dos personas dejan de poder leerse, en los dos
 * sentidos y para siempre: volver a ser amigos no devuelve el acceso (ADR 0064). Idempotente.
 */
public interface RevokeNoteRecipientsUseCase {

    void revokeBetween(UUID userId, UUID otherUserId);
}
