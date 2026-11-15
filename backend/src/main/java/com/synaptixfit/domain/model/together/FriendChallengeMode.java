package com.synaptixfit.domain.model.together;

/**
 * Cómo se juega un reto con amigos (ADR 0044). Juntos (por defecto): una meta común que es la suma del grupo.
 * Competición (opcional): cada uno suma sus puntos con el mismo tope diario, para no premiar el exceso.
 */
public enum FriendChallengeMode {
    COOPERATIVE,
    COMPETITION
}
