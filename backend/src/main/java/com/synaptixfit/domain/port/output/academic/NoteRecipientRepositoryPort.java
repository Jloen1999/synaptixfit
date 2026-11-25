package com.synaptixfit.domain.port.output.academic;

import java.time.Instant;
import java.util.UUID;

/**
 * A quién se ha pasado cada apunte (ADR 0064): «Compartir › Con un amigo» deja leer ese apunte a esa persona aunque
 * sea privado. Se borra solo con el apunte o con la cuenta (claves foráneas en cascada).
 */
public interface NoteRecipientRepositoryPort {

    /** Apunta que {@code recipientId} puede leer el apunte; repetirlo no cambia nada. */
    void add(UUID noteId, UUID recipientId, Instant at);

    boolean isRecipient(UUID noteId, UUID userId);

    /** Quita los apuntes que cada uno pasó al otro (los dos sentidos). */
    void deleteBetween(UUID userId, UUID otherUserId);
}
