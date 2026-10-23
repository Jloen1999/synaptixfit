package com.synaptixfit.domain.model.admin;

import java.time.Instant;
import java.util.UUID;

/**
 * Evento de la línea de tiempo de un usuario. {@code title} es el nombre del elemento (rutina,
 * reto, insignia, código de acción…) y {@code value} una magnitud opcional en minutos.
 */
public record TimelineEntry(Instant occurredAt, Type type, UUID referenceId, String title, Integer value) {

    /** Tipo de evento. */
    public enum Type {
        ACCOUNT_CREATED,
        TRAINING_SESSION,
        ROUTINE_CREATED,
        CHALLENGE_CREATED,
        CHALLENGE_COMPLETED,
        BADGE_EARNED,
        STUDY_BLOCK_COMPLETED,
        DEADLINE_COMPLETED,
        NOTE_CREATED,
        FOCUS_SESSION,
        POST_PUBLISHED,
        COMMENT_POSTED,
        ADMIN_ACTION
    }
}
