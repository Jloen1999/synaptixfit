package com.synaptixfit.domain.model.social;

/** Listados de relaciones del usuario. */
public enum FriendshipListKind {
    /** Amistades aceptadas. */
    FRIENDS,
    /** Solicitudes pendientes recibidas. */
    RECEIVED,
    /** Solicitudes pendientes enviadas. */
    SENT,
    /** Usuarios bloqueados por mí. */
    BLOCKED
}
