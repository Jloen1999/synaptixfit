package com.synaptixfit.domain.model.social;

import java.util.UUID;

/** Relación vista desde un usuario concreto (para pintar el botón correcto en el cliente). */
public enum FriendshipRelation {
    NONE,
    REQUEST_SENT,
    REQUEST_RECEIVED,
    FRIENDS,
    /** El usuario que mira ha bloqueado al otro. */
    BLOCKED;

    /**
     * Calcula la relación para {@code viewerId}. Una solicitud rechazada o un bloqueo sufrido se
     * ven como {@link #NONE}: no se revela que se ha sido rechazado o bloqueado.
     */
    public static FriendshipRelation of(UUID viewerId, FriendshipStatus status, UUID requesterId) {
        if (status == null) {
            return NONE;
        }
        boolean viewerIsRequester = viewerId.equals(requesterId);
        return switch (status) {
            case ACCEPTED -> FRIENDS;
            case PENDING -> viewerIsRequester ? REQUEST_SENT : REQUEST_RECEIVED;
            case BLOCKED -> viewerIsRequester ? BLOCKED : NONE;
            case REJECTED -> NONE;
        };
    }
}
