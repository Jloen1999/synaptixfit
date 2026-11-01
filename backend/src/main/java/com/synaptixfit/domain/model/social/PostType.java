package com.synaptixfit.domain.model.social;

/** Tipo de publicación del muro: logro automático o contenido compartido (rutina o reto). */
public enum PostType {
    SESSION_COMPLETED,
    CHALLENGE_COMPLETED,
    MILESTONE_REACHED,
    BADGE_UNLOCKED,
    ROUTINE,
    CHALLENGE;

    /**
     * ¿Se puede publicar a mano? «Rutina» y «Reto» no: una publicación así no enlaza ninguna rutina
     * ni reto real (no hay metadatos validados), así que solo se conservan las antiguas.
     */
    public boolean publishableByHand() {
        return this != ROUTINE && this != CHALLENGE;
    }
}
